import { sensor } from '@kit.SensorServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class ShakeTrigger {
  private impulses: number[] = [];
  private lastImpulse: number = 0;
  private armed: boolean = true;
  private listening: boolean = false;
  start(onShake: () => void): void {
    sensor.on(sensor.SensorId.ACCELEROMETER, (event: sensor.AccelerometerResponse): void => {
      const magnitude = Math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      const now = Date.now();
      if (!this.armed || magnitude < 17 || now - this.lastImpulse < 180) { return; }
      this.lastImpulse = now;
      this.impulses = this.impulses.filter((t: number): boolean => now - t < 2000);
      this.impulses.push(now);
      hilog.info(0x0001, 'CareGuardian', 'SHAKE impulse=%{public}d magnitude=%{public}f', this.impulses.length, magnitude);
      if (this.impulses.length >= 3) { this.armed = false; this.impulses = []; onShake(); }
    }, { interval: 50000000 });
    this.listening = true;
  }
  arm(): void { this.armed = true; this.impulses = []; }
  stop(): void {
    if (this.listening) { sensor.off(sensor.SensorId.ACCELEROMETER); }
    this.listening = false;
  }
}
