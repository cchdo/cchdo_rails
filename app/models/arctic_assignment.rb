class ArcticAssignment < ActiveRecord::Base
   set_table_name "arctic_assignments"
   
   def before_update
      old_object = ArcticAssignment.find(self.id)
      change = false
      for column in ArcticAssignment.columns
         col_name = column.name
         if col_name !~ /(history)|(manager)/
            if old_object[:"#{col_name}"] != self[:"#{col_name}"]
               change = true
               old_val = old_object[:"#{col_name}"]
               new_val = self[:"#{col_name}"]
               t_now = Time.now.strftime("%m/%d/%Y %I:%M")
               self.history << "#{t_now} #{col_name}: #{old_val} -> #{new_val}\n"
               user = self.manager
               self.LastChanged = Time.now.strftime("%Y-%m-%d")
            end
         end
      end
      if change
         self.history << "Modified by #{user}\n\n "
      else
         self.manager = old_object.manager
      end
   end

   def before_create
      user = self.manager
      t_now = Time.now.strftime("%m/%d/%Y %I:%M")
      self.history = "#{t_now} Created by #{user}\n"
      self.LastChanged = Time.now.strftime("%Y-%m-%d")
   end
   
   #def after_save
   #   record = AuditTrail.find(:first, :conditions => [" record_id = #{self.id} and time = #{self.changed}"])
   #   user = record[:user_id]
   #   self.history << "#{user}\n\n"
   #end

end
