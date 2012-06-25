# encoding: utf-8

class Reachability

	@@ids = {}

	attr_reader :callback

	def initialize( target, callback = nil, status_callback = self.method( :network_status ).to_proc )
		@target = target
		@callback = callback
		@determine_status = status_callback
		ObjectSpace.define_finalizer( self, self.class.method( :finalize ).to_proc )
	end

	def self.finalize( obj_id )
		notifier = ObjectSpace._id2ref( obj_id )
		notifier.stop_notifier if notifier
	end

	def self.with_hostname( hostname, &callback )
		ref = SCNetworkReachabilityCreateWithName( KCFAllocatorDefault, hostname.UTF8String )
		raise "bad hostname: #{hostname}" unless ref
		Reachability.new( ref, callback )
	end

	def self.with_address( address, &callback )
		ref = SCNetworkReachabilityCreateWithAddress( KCFAllocatorDefault, address )
		raise "bad address: #{address}" unless ref
		Reachability.new( ref, callback )
	end

	def self.for_internet( &callback )
		internet = Object.new
		Reachability.with_address( internet, callback )
	end

	def self.for_wifi( &callback )
		wifi = Object.new
		Reachability.with_address( wifi, callback, self.method( :wifi_status ).to_proc )
	end

	def start_notifier
		return false if @@ids.key? @target.object_id
		context_ptr = Pointer.new( SCNetworkReachabilityContext.type )
		if SCNetworkReachabilitySetCallback( @target, @@callback_handler, context_ptr )
			if SCNetworkReachabilityScheduleWithRunLoop( @target, CFRunLoopGetCurrent(), KCFRunLoopDefaultMode )
				@@ids[ @target.object_id ] = self
				return true
			end
		end
	end

	def stop_notifier
		return true unless @@ids.key? @target.object_id
		SCNetworkReachabilityUnscheduleFromRunLoop( @target, CFRunLoopGetCurrent(), KCFRunLoopDefaultMode )
		@@ids.delete( @target.object_id )
	end

	@@callback_handler = Proc.new do |target, flags, pointer|
		return unless @@ids.key? target.object_id
		notifier = @@ids[ target.object_id ]
		notifier.instance_variable_set( :@flags, flags )
		notifier.callback.call( notifier ) unless notifier.callback.nil?
	end

	def current_status
		@determine_status.call( @flags )
	end

	def connection_required?
		return true unless @flags
		ftest( KSCNetworkReachabilityFlagsConnectionRequired )
	end

private

	def network_status
		return :NotReachable unless ftest( KSCNetworkReachabilityFlagsReachable )
		return :ReachableViaWWAN if ftest( KSCNetworkReachabilityFlagsIsWWAN )
		connReq = ftest( KSCNetworkReachabilityFlagsConnectionRequired )
		connOnDemand = ftest( KSCNetworkReachabilityFlagsConnectionOnDemand )
		connOnTraffic = ftest( KSCNetworkReachabilityFlagsConnectionOnTraffic )
		interventionReq = ftest( KSCNetworkReachabilityFlagsInterventionRequired )
		return :ReachableViaWiFi if !connReq || ((connOnDemand || connOnTraffic) && !interventionReq)
		:NotReachable
	end

	def wifi_status
		reachable = ftest( KSCNetworkReachabilityFlagsReachable )
		is_direct = ftest( KSCNetworkReachabilityFlagsIsDirect )
		return :ReachableViaWiFi if reachable && is_direct
		:NotReachable
	end

	def ftest( reference )
		return false unless @flags
		(@flags & reference) != 0
	end

end
