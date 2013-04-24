module Staff::QueueHelper
    def cls_to_title(cls)
      cls.capitalize
    end

    def cls_to_query(cls)
      q = {}
      s, t = cls.split(' ')
      if ['hidden', 'merged'].include?(s)
        q[:merge_status] = s
      end
      if t == 'docs'
        q[:docs] = 'y'
      end
      q
    end

    def cls()
        cls_status_doc(params[:merge_status], @documentation)

        if not params[:id].nil?
          cls = 'id'
        elsif not params[:expocode].nil?
          cls = 'expocode'
        end
        cls
    end

    def qfile_status(qfile)
        if qfile.Merged == 0
            'unmerged'
        elsif qfile.Merged == 1
            'merged'
        elsif qfile.Merged == 2
            'hidden'
        end
    end

    def cls_status_doc(mstatus, doc)
        cls = []

        if not ['hidden', 'merged'].include?(mstatus)
          mstatus = 'unmerged'
        end
        cls << mstatus

        if doc== 1
          cls << 'docs'
        else
          cls << 'data'
        end
        cls.join(' ')
    end
end
