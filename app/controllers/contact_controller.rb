class ContactController < ApplicationController
   def index
      show_contact
      if not params[:contact].blank?
         redirect_to :action => 'show_contact', :contact => params[:contact]
      elsif not params[:id].blank?
         redirect_to :action => 'show_contact', :id => params[:id]
      else
         redirect_to root_path
      end
   end
   
   def show_contact
       if params[:contact] =~ /\w/
           @contact = Contact.find_by_LastName(params[:contact])
           @contact.Address.gsub!(/\n/,"<br>")
       elsif params[:id] =~ /\w/
           @contact = Contact.find(params[:id])
           @contact.Address.gsub!(/\n/,"<br>")
       end
   end
end
