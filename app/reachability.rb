# encoding: utf-8

class Reachability

	attr_reader :callback

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
		WifiReachability.with_address( wifi, callback )
	end

	def start_notifier
		return false if @@ids.key? @target.object_id
		@context_ptr = @context_ptr || Pointer.new( SCNetworkReachabilityContext.type )
		if SCNetworkReachabilitySetCallback( @target, @@callback_handler, @context_ptr )
			if SCNetworkReachabilityScheduleWithRunLoop( @target, CFRunLoopGetCurrent(), KCFRunLoopDefaultMode )
				@@ids[ @target.object_id ] = self
				return true
			end
		end
	end

	def stop_notifier
		return true unless @@ids.key? @target.object_id
		SCNetworkReachabilityUnscheduleFromRunLoop( @target, CFRunLoopGetCurrent(), KCFRunLoopDefaultMode )
		SCNetworkReachabilitySetCallback( @target, nil, @context_ptr )
		@@ids.delete( @target.object_id )
		@context_ptr = nil
	end

	def current_status
		return :NotReachable unless ftest( KSCNetworkReachabilityFlagsReachable )
		return :ReachableViaWWAN if ftest( KSCNetworkReachabilityFlagsIsWWAN )
		connReq = ftest( KSCNetworkReachabilityFlagsConnectionRequired )
		connOnDemand = ftest( KSCNetworkReachabilityFlagsConnectionOnDemand )
		connOnTraffic = ftest( KSCNetworkReachabilityFlagsConnectionOnTraffic )
		interventionReq = ftest( KSCNetworkReachabilityFlagsInterventionRequired )
		return :ReachableViaWiFi if !connReq || ((connOnDemand || connOnTraffic) && !interventionReq)
		:NotReachable
	end

	def connection_required?
		return true unless @flags
		ftest( KSCNetworkReachabilityFlagsConnectionRequired )
	end

	@@callback_handler = Proc.new do |target, flags, pointer|
		# workaround as pointer will have a (corrupted)
		# reference to a Fixnum instance
		return unless @@ids.key? target.object_id
		notifier = @@ids[ target.object_id ]

		# NOTE is there way to do this w/o introspection
		# and without exposing access to instance variable??
		notifier.instance_variable_set( :@flags, flags )

		# call update block
		notifier.callback.call( notifier ) unless notifier.callback.nil?
	end

	def self.finalize( obj_id )
		notifier = ObjectSpace._id2ref( obj_id )
		notifier.stop_notifier if notifier && notifier.kind_of?( Reachability )
	end

protected

	def ftest( reference )
		return false unless @flags
		(@flags & reference) != 0
	end

private

	# workaround to @context_ptr[ 0 ].info
	# being diferent every time it is accessed
	@@ids = {}

	def initialize( target, callback = nil )
		@target = target
		@callback = callback
		ObjectSpace.define_finalizer( self, self.class.method( :finalize ).to_proc )
	end

end

class WifiReachability < Reachability

	def current_status
		reachable = ftest( KSCNetworkReachabilityFlagsReachable )
		is_direct = ftest( KSCNetworkReachabilityFlagsIsDirect )
		return :ReachableViaWiFi if reachable && is_direct
		:NotReachable
	end

private

	def initialize( target, callback = nil )
		super( target, callback )
	end

end
