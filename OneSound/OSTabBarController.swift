//
//  OSTabBarController.swift
//  OneSound
//
//  Created by adam on 1/5/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

class OSTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.backgroundImage = UIImage(named: "tabBarBackground")
        tabBar.shadowImage = UIImage(named: "tabBarShadow")
        tabBar.tintColor = UIColor.blue()
        tabBar.barTintColor = UIColor.white()
        tabBar.translucent = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
