//
//  TestViewController.swift
//  OneSound
//
//  Created by adam on 7/7/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        for i in 1...4 {
            OSAPI.sharedAPI.GETUser(i,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    println(responseJSON)
                },
                failure: defaultAFHTTPFailureBlock
            )
        }
        /*
        for i in 1...4 {
            OSAPI.sharedAPI.GETUserFollowing(i,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    println(responseJSON)
                },
                failure: defaultAFHTTPFailureBlock
            )
        }
        
        for i in 1...4 {
            OSAPI.sharedAPI.GETUserFollowers(i,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    println(responseJSON)
                },
                failure: defaultAFHTTPFailureBlock
            )
        }
        */
    
    }

}
