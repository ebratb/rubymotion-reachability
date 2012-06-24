# encoding: utf-8

class Reachability

	# NetworkStatus = [ :NotReachable, :ReachableViaWiFi, :ReachableViaWWAN ]

	KReachabilityChangedNotification = 'kNetworkReachabilityChangedNotification'

	attr_accessor :local_wifi_ref, :target, :callback

	def self.with_hostname( hostname, &callback )
		ref = SCNetworkReachabilityCreateWithName( KCFAllocatorDefault, hostname.UTF8String )
		raise "bad hostname: #{hostname}" unless ref
		reach = Reachability.new
		reach.target = ref
		reach.callback = callback if block_given?
		reach
	end

	def self.with_address( address, &callback )
		ref = SCNetworkReachabilityCreateWithAddress( KCFAllocatorDefault, address )
		raise "bad address: #{address}" unless ref
		Reachability.setup( ref, callback )
	end

	def self.for_internet( &callback )
		internet = Object.new
		Reachability.with_address( internet, callback )
	end

	def self.for_wifi( &callback )
		wifi = Object.new
		Reachability.with_address( wifi, callback )
	end

	def start_notifier
		self_ptr = Pointer.new( :object )
		self_ptr[ 0 ] = self
		context_ptr = Pointer.new( SCNetworkReachabilityContext.type )
		context_ptr[ 0 ] = SCNetworkReachabilityContext.new( 0, self_ptr, nil, nil, nil )
		callback_handler = Proc.new do |target, flags|
			puts "callback being called..."
			# reachability.callback( target, flags, reachability )
		end
		if SCNetworkReachabilitySetCallback( target, :callback_handler, context_ptr )
			return SCNetworkReachabilityScheduleWithRunLoop( target, CFRunLoopGetCurrent(), KCFRunLoopDefaultMode )
		end
	end

	def stop_notifier
		
	end

	def current_status
		
	end

	def connection_required?
		true
	end

	def callback_handler( target, flags, reachability )
		puts "instance callback_handler..."
	end

	def self.callback_handler( target, flags, reachability )
		puts "class callback_handler..."
	end

private

	def self.setup( target, &callback )
		reach = Reachability.new
		reach.target = target
		reach.callback = callback if block_given?
		reach
	end

end
