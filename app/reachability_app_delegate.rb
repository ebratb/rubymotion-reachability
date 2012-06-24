# encoding: utf-8

class ReachabilityAppDelegate

	attr_accessor :window, :content_view
	attr_accessor :hostname_label, :summary_label
	attr_accessor :hostname_icon, :hostname_status
	attr_accessor :internet_icon, :internet_status
	attr_accessor :wifi_icon, :wifi_status

	def application( application, didFinishLaunchingWithOptions: launchOptions )
		@window = UIWindow.alloc.initWithFrame( UIScreen.mainScreen.bounds )
		@window.rootViewController = NSBundle.mainBundle.loadNibNamed( 'Reachability', owner: self, options: nil ).first
		@window.rootViewController.wantsFullScreenLayout = true

		# observe the kNetworkReachabilityChangedNotification and when posted, cal "reachability_changed" method
		NSNotificationCenter.defaultCenter.addObserver( self,
			selector: 'reachability_changed',
			name: Reachability::KReachabilityChangedNotification,
			object: nil
		)

		# hostname setup
		hostname = 'www.apple.com'
		hostname_label.text = "Remote Host: #{hostname}"

		# monitor registry setup
		@monitors = []

		# hostname reachability
		@monitors << Reachability.with_hostname( hostname ) do |monitor|
			configure_text_field( monitor, hostname_icon, hostname_status )
			summary_label.hidden = (monitor.current_status != :ReachableViaWWAN)
			summary_label.text = if monitor.connection_required?
				"Cellular data network is available.\n  Internet traffic will be routed through it after a connection is established."
			else
				"Cellular data network is active.\n  Internet traffic will be routed through it."
			end
		end

		# internet reachability
		@monitors << Reachability.for_internet do |monitor|
			configure_text_field( monitor, internet_icon, internet_status )
		end

		# wifi reachability
		@monitors << Reachability.for_wifi do |monitor|
			configure_text_field( monitor, wifi_icon, wifi_status )
		end

		# start monitors
		@monitors.each( &:start_notifier )

		# now show main screen
		@window.makeKeyAndVisible
		true
	end

	def reachability_changed( note )
		current = note.object
		current.handle_event if current.kind_of? Reachability
	end

	def configure_text_field( monitor, icon, status )
		conn_required = monitor.connection_required?
		status_text = ''
		case monitor.current_status
			when :NotReachable
				status_text = 'Access Not Available'
				icon.image = UIImage.imageNamed( 'stop.png' )
				# minor interface detail- connectionRequired may return yes,
				# even when the host is unreachable.
				conn_required = false
			when :ReachableViaWWAN
				status_text = 'Reachable WWAN'
				icon.image = UIImage.imageNamed( 'wwan.png' )
			when :ReachableViaWiFi
				status_text = 'Reachable WiFi'
				icon.image = UIImage.imageNamed( 'wifi.png' )
		end
		status_text = "#{status_text}, Connection Required" if conn_required
		status.text= status_text
	end

end
