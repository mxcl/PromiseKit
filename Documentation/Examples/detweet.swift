#!/usr/bin/swift sh
import Foundation
import PromiseKit  // @mxcl ~> 6.5 
import Swifter     // @mattdonnelly == b27a89
let swifter = Swifter(
	consumerKey: "FILL",
	consumerSecret: "ME",
	oauthToken: "IN",
	oauthTokenSecret: "https://developer.twitter.com/en/docs/basics/apps/overview.html"
)

extension JSON {
    var date: Date? {
        guard let string = string else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        return formatter.date(from: string)
    }
}

let twoMonthsAgo = Date() - 24*60*60*30*2

print("Deleting qualifying tweets before:", twoMonthsAgo)

func deleteTweets(maxID: String? = nil) -> Promise<Void> {
    return Promise { seal in
        swifter.getTimeline(for: "mxcl", count: 200, maxID: maxID, success: { json in

            if json.array!.count <= 1 {
                // if we get one result for a requested maxID, we're done
                return seal.fulfill()
            }

            for item in json.array! {
                let date = item["created_at"].date!
                guard date < twoMonthsAgo, item["favorite_count"].integer! < 2 else {
                    continue
                }
                swifter.destroyTweet(forID: id, success: { _ in
                    print("D:", item["text"].string!)
                }, failure: seal.reject)
            }

            let next = json.array!.last!["id_str"].string!
            deleteTweets(maxID: next).pipe(to: seal.resolve)

        }, failure: seal.reject)
    }
}

func deleteFavorites(maxID: String? = nil) -> Promise<Void> {
    return Promise { seal in
        swifter.getRecentlyFavoritedTweets(count: 200, maxID: maxID, success: { json in

            if json.array!.count <= 1 {
                return seal.fulfill()
            }

            for item in json.array! {
                guard item["created_at"].date! < twoMonthsAgo else { continue }

                swifter.unfavoriteTweet(forID: item["id_str"].string!, success: { _ in
                    print("D❤️:", item["text"].string!)
                }, failure: seal.reject)
            }
            
            let next = json.array!.last!["id_str"].string!
            deleteFavorites(maxID: next).pipe(to: seal.resolve)

        }, failure: seal.reject)
    }
}

func unblockPeople(cursor: String? = nil) -> Promise<Void> {
    return Promise { seal in
        swifter.getBlockedUsersIDs(stringifyIDs: "true", cursor: cursor, success: { json, prev, next in
            for id in json.array! {
                print("Unblocking:", id)
                swifter.unblockUser(for: .id(id.string!))
            }

            if let next = next, !next.isEmpty, next != prev, next != "0" {
                unblockPeople(cursor: next).pipe(to: seal.resolve)
            } else {
                seal.fulfill()
            }

        }, failure: seal.reject)
    }
}

firstly {
    when(fulfilled: deleteTweets(), deleteFavorites(), unblockPeople())
}.done {
    exit(0)
}.catch {
    print("error:", $0)
    exit(1)
}

RunLoop.main.run()
