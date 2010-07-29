class ContactController < ApplicationController
   def index
      show_contact
      if params[:contact] =~ /\w/ 
         redirect_to  :action => 'show_contact', :contact => params[:contact]
      elsif params[:id] =~ /\w/
         redirect_to :action => 'show_contact' , :id => params[:id]
      else
         redirect_to "http://cchdo.ucsd.edu"
      end
   end
   
   def show_contact
     if params[:contact] =~ /\w/
      @contact = Contact.find(:first, :conditions => ["`LastName` = '#{params[:contact]}' "])
      @contact.Address.gsub!(/\n/,"<br>")
      logger.info @contact.inspect
      #@cruises = Cruise.find(:all,:conditions => ["`Chief_Scientist` regexp '#{params[:contact]}'"])
     elsif params[:id] =~ /\w/
       @contact = Contact.find(params[:id])
       @contact.Address.gsub!(/\n/,"<br>")
       #@cruises = ContactCruise.find(:all,:conditions => ["`Chief_Scientist` regexp '#{params[:contact]}'"])
     end
   end

end
