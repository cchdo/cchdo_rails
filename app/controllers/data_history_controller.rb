class DataHistoryController < ApplicationController
   def index
      history
      @expo=params[:ExpoCode]
      @note = params[:Note]
      @cur_sort = params[:Sort]
      if(@expo)
         render :action => 'history'
      else
         redirect_to "http://cchdo.ucsd.edu/data_access"
      end
   end
   
   def history
      @expo = params[:ExpoCode]
      @note = params[:Note]
      @entry = params[:Entry]
      @cur_sort = params[:Sort]
      @updated = Event.find_by_sql("SELECT * FROM events ORDER BY Date_Entered DESC LIMIT 1")
      #@updated = Event.find(:first,:order=>'Date_Entered DESC')
      if (@expo)
         if(@cur_sort == "LastName")
            @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['LastName'])
         elsif( @cur_sort == "Data_Type")
            @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['Data_Type'])
         else
            @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['Date_Entered DESC'])
         end
         @cruise = Cruise.find(:first,:conditions=>["ExpoCode='#{@expo}'"])
      end
      if (@note)
         @note_entry = Event.find(:first,:conditions=>["ID=#{@entry}"])
         @note_entry[:Note].gsub!(/[\n\r\f]/,"<br>")
         @note_entry[:Note].gsub!(/[\t]/,"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
      end      
   end
   
   def full
     @expo=params[:ExpoCode]
     @note = params[:Note]
     @cur_sort = params[:Sort]
     @notes = []
     if(@expo)
        @updated = Event.find_by_sql("SELECT * FROM events ORDER BY Date_Entered DESC LIMIT 1")
         #@updated = Event.find(:first,:order=>'Date_Entered DESC')
         if (@expo)
            if(@cur_sort == "LastName")
               @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['LastName'])
            elsif( @cur_sort == "Data_Type")
               @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['Data_Type'])
            else
               @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['Date_Entered DESC'])
            end
            @cruise = Cruise.find(:first,:conditions=>["ExpoCode='#{@expo}'"])
         end
     else
        redirect_to "http://cchdo.ucsd.edu/data_access"
     end
   end
   
end
