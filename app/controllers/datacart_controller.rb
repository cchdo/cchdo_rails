require 'time'
require 'tempfile'
require 'zip/zip'

include ActionView::Helpers::TextHelper

class DatacartController < ApplicationController
    $zip_file_limit = 20
    $tempname = 'data_cart_zip'

    def index
    end

    def add
        dirid = params[:dirid].to_i
        file = params[:file]
        document = Document.find_by_id(dirid)
        if not document or not document.Files.include?(file)
            flash[:notice] = 'Error adding file to data cart.'
            raise ActionController:RoutingError.new('Not Found')
        end
        @datacart << [dirid, file]
        session['datacart'] = @datacart
        if request.xhr?
            render :json => {:cart_count => @datacart.length}, :status => :ok
        else
            flash[:notice] = "Added #{file} to data cart"
            redirect_to :back
        end
    rescue ActionController::RedirectBackError
        redirect_to datacart_path
    end

    def add_cruise
        cruise_id = params[:cruise_id]
        cruise = Cruise.find_by_id(cruise_id)
        if not cruise
            flash[:notice] = 'Error adding cruise dataset to data cart.'
            raise ActionController::RoutingError.new('Not found')
        end

        before_count = @datacart.length

        dir = cruise.directory
        mapped_files = cruise.get_files()
        file_count = 0
        for key, file in mapped_files
            next if key =~ /_pic$/
            @datacart << [dir.id, File.basename(file)]
            file_count += 1
        end
        session['datacart'] = @datacart

        after_count = @datacart.length
        count_diff = after_count - before_count

        if request.xhr?
            render :json => {:cart_count => @datacart.length,
                             :diff => count_diff},
                   :status => :ok
        else
            message = "Added #{pluralize(count_diff, 'file')} to datacart"
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
            flash[:notice] = 'Error removing file from data cart.'
            raise ActionController:RoutingError.new('Not Found')
        end
        session['datacart'] = @datacart.delete([dirid, file])
        if request.xhr?
            render :json => {:cart_count => @datacart.length}, :status => :ok
        else
            flash[:notice] = "Removed #{file} from data cart"
            redirect_to :back
        end
    rescue ActionController::RedirectBackError
        redirect_to datacart_path
    end

    def remove_cruise
        cruise_id = params[:cruise_id]
        cruise = Cruise.find_by_id(cruise_id)
        if not cruise
            flash[:notice] = 'Error removing cruise dataset from data cart.'
            raise ActionController::RoutingError.new('Not found')
        end

        before_count = @datacart.length

        dir = cruise.directory
        mapped_files = cruise.get_files()
        file_count = 0
        for key, file in mapped_files
            next if key =~ /_pic$/
            @datacart = @datacart.delete([dir.id, File.basename(file)])
            file_count += 1
        end
        session['datacart'] = @datacart

        after_count = @datacart.length
        count_diff = before_count - after_count

        if request.xhr?
            render :json => {:cart_count => @datacart.length,
                             :diff => count_diff},
                   :status => :ok
        else
            message = "Removed #{pluralize(count_diff, 'file')} from data cart"
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
        session.delete('datacart')
        if request.xhr?
            render :json => {:cart_count => 0}, :status => :ok
        else
            flash[:notice] = 'Cleared data cart'
            redirect_to :back
        end
    rescue ActionController::RedirectBackError
        redirect_to datacart_path
    end

    def download
        unless request.post?
            raise ActionController::UnknownAction
        end

        archive = params[:archive].to_i
        to_dl = @datacart.to_a.slice(archive * $zip_file_limit, $zip_file_limit)

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
        redirect_to datacart_path
    end

private

    def cleanup_downloads
        # Delete datacart tempfiles older than 10 minutes.
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
