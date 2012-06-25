describe "Pointer class in RubyMotion" do

	before do
		# referenced data setup
		@info = Object.new
		@info_ptr = Pointer.new( :object )

		# context pointer setup
		@context = SCNetworkReachabilityContext.new
		@context.info = @info_ptr # info expects a reference to some data
		@context_ptr = Pointer.new( SCNetworkReachabilityContext.type )
	end

  it "keeps pointer references to ruby objects unchanged" do
		@info_ptr[ 0 ] = @info
		@info.should.be.same_as @info_ptr[ 0 ]
  end

  it "keeps pointer references inside structures unchanged" do
		@context_ptr[ 0 ] = @context
		@context.should.be.same_as @context_ptr[ 0 ]
  end

  it "has a description for 'sockaddr' structures" do
		struct_type = '{sockaddr=CC[14c]}' # got from a program failure
		@address_ptr = Pointer.new_with_type( struct_type )
  end

end
