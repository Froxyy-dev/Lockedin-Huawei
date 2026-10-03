import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';

export interface CareLocation {
  available: boolean;
  latitude?: number;
  longitude?: number;
  simulated: boolean;
}
export async function currentLocation(context: common.UIAbilityContext): Promise<CareLocation> {
  try {
    const access = abilityAccessCtrl.createAtManager();
    const result = await access.requestPermissionsFromUser(context,
      ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']);
    if (result.authResults.some((value: number): boolean => value !== 0)) { return { available: false, simulated: true }; }
    const request: geoLocationManager.SingleLocationRequest = { locatingTimeoutMs: 4000, locatingPriority: geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED };
    const location = await geoLocationManager.getCurrentLocation(request);
    return { available: true, latitude: location.latitude, longitude: location.longitude, simulated: true };
  } catch (error) { return { available: false, simulated: true }; }
}
