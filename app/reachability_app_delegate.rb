# encoding: utf-8

class ReachabilityAppDelegate
	attr_accessor :window, :contentView, :summaryLabel
	attr_accessor :remoteHostLabel, :remoteHostIcon, :remoteHostStatusField
	attr_accessor :internetConnectionIcon, :internetConnectionStatusField
	attr_accessor :localWiFiConnectionIcon, :localWiFiConnectionStatusField
	attr_accessor :hostReach, :internetReach, :wifiReach

	def application( application, didFinishLaunchingWithOptions:launchOptions )
		@window = UIWindow.alloc.initWithFrame( UIScreen.mainScreen.bounds )
		@window.rootViewController = NSBundle.mainBundle.loadNibNamed( 'Reachability', owner:self, options:nil ).first
		@window.rootViewController.wantsFullScreenLayout = true
		@window.makeKeyAndVisible
		true
	end

	def applicationDidFinishLaunching( application )
		contentView.backgroundColor = UIColor.groupTableViewBackgroundColor
#		summaryLabel.hidden = true

		# Observe the KNetworkReachabilityChangedNotification. When that notification
		# is posted, the method "reachabilityChanged" will be called.
#		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	end

end
