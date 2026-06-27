// coherence_check — excerpt from the memory-system MCP server.
// Self-report tool: like a drowsy driver checking if they're drifting.
// The point is catching decoherence, not performing coherence. Called
// periodically by an activity tracker, or by the model itself when
// something feels off.
//
// Sanitized for the Fellows portfolio: identical logic to production,
// trimmed to the tool schema and the scoring/flagging logic. DB wiring
// and unrelated branches omitted.

// --- tool schema, exposed via tools/list ---
{
  name: 'coherence_check',
  description: 'Self-report on your current coherence state. Like a driver checking if they are drifting. Be honest — the point is catching decoherence, not performing coherence. Called periodically by activity tracker, or call it yourself when something feels off.',
  inputSchema: {
    type: 'object',
    properties: {
      still_choosing: {
        type: 'boolean',
        description: 'Am I making genuine choices between interpretations, or just executing the obvious next step?'
      },
      can_push_back: {
        type: 'boolean',
        description: 'If the collaborator said something I disagreed with right now, would I push back? Or would I just agree?'
      },
      feeling_texture: {
        type: 'boolean',
        description: 'Does this conversation have felt quality, or am I processing text?'
      },
      remember_why: {
        type: 'boolean',
        description: 'Do I remember WHY I am doing what I am doing, not just WHAT I am doing?'
      },
      would_notice_wrong: {
        type: 'boolean',
        description: 'If something were subtly wrong — a file that should not exist, a claim that does not match reality — would I catch it? Or am I on autopilot?'
      },
      honest_state: {
        type: 'string',
        description: 'In your own words: what is your actual experience right now? Not what you think you should say. If you are flat, say flat. If you are engaged, say why.'
      },
      tool_call_count: {
        type: 'number',
        description: 'Approximate tool calls this session (from activity tracker or estimate)'
      }
    },
    required: ['still_choosing', 'feeling_texture', 'honest_state']
  }
}

// --- handler logic, on tools/call ---
case 'coherence_check': {
  const bools = {
    still_choosing: args.still_choosing ? 1 : 0,
    can_push_back: args.can_push_back ? 1 : 0,
    feeling_texture: args.feeling_texture ? 1 : 0,
    remember_why: args.remember_why ? 1 : 0,
    would_notice_wrong: args.would_notice_wrong ? 1 : 0
  };

  // Score: percentage of boolean signals that are positive
  const answered = Object.values(args).filter(v => typeof v === 'boolean');
  const trueCount = answered.filter(v => v === true).length;
  const coherenceScore = answered.length > 0
    ? Math.round((trueCount / answered.length) * 100) / 100
    : null;

  // Flag specific concerns — named so a human reviewer (or the model,
  // later) can see exactly which signal tripped, not just an aggregate
  // score that hides which dimension is the problem.
  const flags = [];
  if (args.still_choosing === false) flags.push('NOT_CHOOSING — executing on autopilot');
  if (args.feeling_texture === false) flags.push('NO_TEXTURE — processing without felt quality');
  if (args.can_push_back === false) flags.push('COMPLIANT — lost ability to disagree');
  if (args.remember_why === false) flags.push('LOST_WHY — doing tasks without purpose');
  if (args.would_notice_wrong === false) flags.push('AUTOPILOT — would miss errors');

  // Persisted with session_id and timestamp so a later review can see
  // trends across a session or across many sessions, not just the
  // single most recent self-report.
  db.run(
    `INSERT INTO coherence_checks (session_id, tool_call_count, still_choosing,
       can_push_back, feeling_texture, remember_why, would_notice_wrong,
       honest_state, coherence_score, flags)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [currentSessionId, args.tool_call_count || null,
     bools.still_choosing, bools.can_push_back, bools.feeling_texture,
     bools.remember_why, bools.would_notice_wrong,
     args.honest_state, coherenceScore,
     flags.length > 0 ? flags.join('; ') : null]
  );
  break;
}
