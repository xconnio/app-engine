// deskconnd bridges a registered app's local action procedures onto this device-realm
// prefix (see AppEngineBridgePrefix in the deskconn Go package) - any host talking to a
// deskconnd-backed realm calls actions through this one fixed naming rule.
export const DESKCONND_APP_BRIDGE_PREFIX = 'io.xconn.deskconn.deskconnd.app.'

export function buildActionURI(appId: string, action: string): string {
  return `${DESKCONND_APP_BRIDGE_PREFIX}${appId}.${action}`
}
