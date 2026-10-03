export const DEMO_PROMPT: string =
  'Build something that helps my elderly parent when their watch detects something unusual.';

export interface Capability {
  name: string;
  icon: Resource;
}

export interface ExperiencePlan {
  goal: string;
  capabilities: Capability[];
  experienceName: string;
}

export const AVAILABLE_CAPABILITIES: Capability[] = [
  { name: 'Watch', icon: $r('app.media.cap_watch') },
  { name: 'Health', icon: $r('app.media.cap_health') },
  { name: 'Voice', icon: $r('app.media.cap_voice') },
  { name: 'Location', icon: $r('app.media.cap_location') },
  { name: 'Notifications', icon: $r('app.media.cap_notifications') },
  { name: 'Accessibility', icon: $r('app.media.cap_accessibility') }
];

// Explicit demo fixture. No AI, permissions, health data or connected devices are used.
// Replace this adapter with a backend-backed planner; pages consume only ExperiencePlan.
export class MockHarmonyPlanner {
  compose(prompt: string): ExperiencePlan {
    return {
      goal: prompt.trim() === DEMO_PROMPT ?
        'Keep my parent safe after unusual watch alerts' : prompt.trim(),
      experienceName: 'Care Guardian',
      capabilities: [
        { name: 'Watch & Health', icon: $r('app.media.cap_health') },
        AVAILABLE_CAPABILITIES[2], AVAILABLE_CAPABILITIES[4],
        AVAILABLE_CAPABILITIES[3], AVAILABLE_CAPABILITIES[5]
      ]
    };
  }
}
