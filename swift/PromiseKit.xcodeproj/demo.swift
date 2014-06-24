import UIKit
import CoreLocation
import PromiseKit
import MapKit


class ViewController: UIViewController, CLLocationManagerDelegate {

    override func viewDidLoad() {
        cats()
        when()
    }

    func cats() {
        let iv = UIImageView(frame:CGRect(x:0, y:100, width: 320, height: 320))
        iv.contentMode = .Center
        view.addSubview(iv)
        title = "Loading Cat"

        NSURLConnection.GET("http://placekitten.com/250/250").then{ (img:UIImage) in
            self.title = "Cat"
            iv.image = img
            return CLGeocoder.geocode(addressString:"Mount Rushmore")
        }.then { (placemark:CLPlacemark) in
            self.title = "Located"
            let opts = MKMapSnapshotOptions()
            opts.region = MKCoordinateRegion(center: placemark.location.coordinate, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
            return MKMapSnapshotter(options:opts).promise()
        }.then { (snapshot:MKMapSnapshot) -> Promise<Int> in
            self.title = "Map Snapshot"
            iv.image = snapshot.image

            let av = UIAlertView()
            av.title = "Hi"
            av.addButtonWithTitle("Bye")
            return av.promise()
        }.then {
            self.title = "You tapped button #\($0)"
        }.then {
            return CLLocationManager.promise()
        }.catch { _ -> CLLocation in
            // If location cannot be determined, default to Chicago
            return CLLocation(latitude: 41.89, longitude: -87.63)
        }.then{ (ll:CLLocation) -> Promise<NSDictionary> in
            let (lat, lon) = (ll.coordinate.latitude, ll.coordinate.longitude)
            return NSURLConnection.GET("http://user.net/\(lat)/\(lon)")
        }.then { (user: NSDictionary) -> Promise<Int> in
            let alert = UIAlertView()
            alert.title = "Hi " + (user["name"] as String)
            alert.addButtonWithTitle("Bye")
            alert.addButtonWithTitle("Hi")
            return alert.promise()
        }.then { (tappedButtonIndex: Int) -> Promise<Void>? in
            if tappedButtonIndex == 0 {
                return nil
            }
            let vc = UIViewController()
            return self.promiseViewController(vc).then { (modallyPresentedResult:String) -> Void in
                //…
            }
        }.catch { (error:NSError) -> Void in
            //…
        }
    }

    func when() {
        let p1:Promise<NSDictionary> = NSURLConnection.GET("http://superpedia.com/random.json")
        let p2 = CLLocationManager.promise().catch{ _ -> CLLocation in
            // in the event of failure to locate, return Cchhicago (ish)
            return CLLocation(latitude:42, longitude: -88)
        }

        //TODO how to make this compile?

//        Promise.when(p1, p2).then{ (hero: NSDictionary, location: CLLocation) -> () in
//
//            let name = hero["name"] as String
//            let home = CLLocation(latitude: hero["lat"] as Double, longitude: hero["lon"] as Double)
//
//            CLGeocoder.reverseGeocode(location).then{ (placemark: CLPlacemark) -> Void in
//                println("\(name) lives at \(placemark).")
//            }
//        }
    }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions: NSDictionary?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window!.backgroundColor = UIColor.whiteColor()
        self.window!.makeKeyAndVisible()
        return true
    }
}
