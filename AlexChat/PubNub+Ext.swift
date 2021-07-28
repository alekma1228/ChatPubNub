//
//  PubNub+Ext.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import PubNub

extension Date {
    var timeIntervalAsImpreciseToken: Int64 {
        return Int64(self.timeIntervalSince1970 * 10000000)
    }
}

extension Message {
    var timeToken: NSNumber {
        return NSNumber(value: sentAt)
    }
}

extension PNStatus {
    var error: NSError? {
        guard let errorStatus = self as? PNErrorStatus, errorStatus.isError else {
            return nil
        }
        return NSError(domain: "\(self.stringifiedOperation()) \(self.stringifiedCategory())",
                code: statusCode,
                userInfo: [
                  NSLocalizedDescriptionKey: "\(self)",
                  NSLocalizedFailureReasonErrorKey: errorStatus.errorData.information
                ])
    }
}

extension PubNub {
    static func configure(with userId: String? = User.defaultValue.uuid, using bundle: Bundle = Bundle.main) -> PubNub {
        let config = PNConfiguration(publishKey: "pub-c-fdd20a63-fd16-4a8f-930d-6cb72eb6d916", subscribeKey: "sub-c-60714650-c300-11eb-8a3a-220055b20f11")
        config.uuid = "3dcde054-17ec-48ba-88f9-93fca230ca8a"
        return PubNub.clientWithConfiguration(config)
  }
}
