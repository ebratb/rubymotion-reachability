# encoding: utf-8

class ReachabilityViewController < UIViewController

	def viewDidLoad
		icon_name = 'stop.png'
		set_widget( :content_view,    1000 ).backgroundColor = UIColor.groupTableViewBackgroundColor
		set_widget( :hostname_label,  1001 )
		set_widget( :hostname_icon,   1002 ).image = UIImage.imageNamed( icon_name )
		set_widget( :hostname_status, 1003 )
		set_widget( :internet_icon,   1005 ).image = UIImage.imageNamed( icon_name )
		set_widget( :internet_status, 1006 )
		set_widget( :wifi_icon,       1008 ).image = UIImage.imageNamed( icon_name )
		set_widget( :wifi_status,     1009 )
		set_widget( :summary_label,   1010 ).hidden = true
	end

private

	def set_widget( attr_name, tag_id )
		delegate = UIApplication.sharedApplication.delegate
		widget = self.view.viewWithTag( tag_id )
		delegate.send( "#{attr_name.to_s}=".to_sym, widget )
		return widget
	end

end
