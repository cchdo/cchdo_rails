require 'time'
require 'tempfile'
require 'zip/zip'

include ActionView::Helpers::TextHelper

class BulkController < ApplicationController
    $zip_file_limit = 20
    $tempname = 'bulk_dl_zip'

    def index
    end

    def add
        dirid = params[:dirid].to_i
        file = params[:file]
        document = Document.find_by_id(dirid)
        if not document or not document.Files.include?(file)
            flash[:notice] = 'Error adding file to bulk download list.'
            raise ActionController:RoutingError.new('Not Found')
        end
        @bulk << [dirid, file]
        session['bulk'] = @bulk
        if request.xhr?
            render :json => {:cart_count => @bulk.length}, :status => :ok
        else
            flash[:notice] = "Added #{file} to bulk download list"
            redirect_to :back
        end
    rescue ActionController::RedirectBackError
        redirect_to bulk_path
    end

    def add_cruise
        cruise_id = params[:cruise_id]
        cruise = Cruise.find_by_id(cruise_id)
        if not cruise
            flash[:notice] = 'Error adding cruise dataset to bulk download list.'
            raise ActionController::RoutingError.new('Not found')
        end

        before_count = @bulk.length

        dir = cruise.directory
        mapped_files = get_files_from_cruise(cruise)
        file_count = 0
        for key, file in mapped_files
            next if key =~ /_pic$/
            @bulk << [dir.id, File.basename(file)]
            file_count += 1
        end
        session['bulk'] = @bulk

        after_count = @bulk.length
        count_diff = after_count - before_count

        if request.xhr?
            render :json => {:cart_count => @bulk.length}, :status => :ok
        else
            message = "Added #{pluralize(count_diff, 'file')} to " + \
                             "bulk download list"
            present_count = file_count - count_diff
            if present_count > 0
                message += " (#{present_count} already present)."
            else
                message += "."
            end
            flash[:notice] = message
            redirect_to :back
        end
    end

    def remove
        dirid = params[:dirid].to_i
        file = params[:file]
        document = Document.find_by_id(dirid)
        if not document or not document.Files.include?(file)
            flash[:notice] = 'Error removing file from bulk download list.'
            raise ActionController:RoutingError.new('Not Found')
        end
        session['bulk'] = @bulk.delete([dirid, file])
        if request.xhr?
            render :json => {:cart_count => @bulk.length}, :status => :ok
        else
            flash[:notice] = "Removed #{file} from bulk download list"
            redirect_to :back
        end
    rescue ActionController::RedirectBackError
        redirect_to bulk_path
    end

    def remove_cruise
        cruise_id = params[:cruise_id]
        cruise = Cruise.find_by_id(cruise_id)
        if not cruise
            flash[:notice] = 'Error removing cruise dataset from bulk download list.'
            raise ActionController::RoutingError.new('Not found')
        end

        before_count = @bulk.length

        dir = cruise.directory
        mapped_files = get_files_from_cruise(cruise)
        file_count = 0
        for key, file in mapped_files
            next if key =~ /_pic$/
            @bulk = @bulk.delete([dir.id, File.basename(file)])
            file_count += 1
        end
        session['bulk'] = @bulk

        after_count = @bulk.length
        count_diff = before_count - after_count

        if request.xhr?
            render :json => {:cart_count => @bulk.length}, :status => :ok
        else
            message = "Removed #{pluralize(count_diff, 'file')} from " + \
                             "bulk download list"
            present_count = file_count - count_diff
            if present_count > 0
                message += " (#{present_count} not present)."
            else
                message += "."
            end
            flash[:notice] = message
            redirect_to :back
        end
    end

    def clear
        unless request.post?
            raise ActionController::UnknownAction
        end
        session.delete('bulk')
        if request.xhr?
            render :json => {:cart_count => 0}, :status => :ok
        else
            flash[:notice] = 'Cleared bulk download list'
            redirect_to :back
        end
    rescue ActionController::RedirectBackError
        redirect_to bulk_path
    end

    def download
        unless request.post?
            raise ActionController::UnknownAction
        end

        set = params[:set].to_i
        to_dl = @bulk.to_a.slice(set * $zip_file_limit, $zip_file_limit)

        paths = []
        for dirid, bfile in to_dl
            paths << [Document.find_by_id(dirid).FileName, bfile]
        end

        cleanup_downloads()
        tfile = Tempfile.new($tempname, tmpdir=TEMPDIR)
        begin
            Zip::ZipOutputStream.open(tfile.path) do |zfile|
                for dirpath, bfile in paths
                    zfile.put_next_entry(bfile)
                    zfile.print(IO.read(File.join(dirpath, bfile)))
                end
            end
        ensure
            tfile.close
        end

        send_file(tfile.path, :type => 'application/zip',
            :disposition => 'attachment',
            :filename => "cchdo_download_#{Time.now.iso8601}.zip")
    rescue ActionController::RedirectBackError
        redirect_to bulk_path
    end

private

    def cleanup_downloads
        # Delete bulk download tempfiles older than 10 minutes.
        threshold = Time.now - 10
        Dir.foreach(TEMPDIR) do |fname|
            next unless fname =~ /^#{$tempname}/
            fpath = File.join(TEMPDIR, fname)
            if File.stat(fpath).mtime < threshold
                File.unlink(fpath)
            end
        end
    end
end
