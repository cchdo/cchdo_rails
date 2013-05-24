require 'digest/sha2'

class User < ActiveRecord::Base
    validates_presence_of :username
    validates_uniqueness_of :username 

    validates_presence_of :password_hash

    validates_uniqueness_of :password_salt

    def password=(password)
        self.password_salt = User.generate_salt
        self.password_hash = get_hash(password)
    end

    def self.authenticate(username, password)
        user = User.find_by_username(username)
        if user.blank? or user.get_hash(password) != user.password_hash
            user = nil
        end
        user
    end

    def get_hash(password)
        Digest::SHA256.hexdigest(password + self.password_salt)
    end

    def editor?
        self.username !~ /guest/
    end

    private

    def self.generate_salt
        # Ensure salt is unique
        begin
            salt = [Array.new(6){rand(256).chr}.join].pack("m").chomp
        end while User.exists?(:password_salt => salt)
        salt
    end

end
