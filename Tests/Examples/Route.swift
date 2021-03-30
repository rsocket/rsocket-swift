import Foundation

func route(_ route: String) -> Data {
    let encodedRoute = Data(route.utf8)
    let encodedRouteLength = Data([UInt8(encodedRoute.count)])

    return encodedRouteLength + encodedRoute
}
