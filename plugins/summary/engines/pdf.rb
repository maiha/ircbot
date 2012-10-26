# requires pdftohtml in poppler (poppler-utils)

module Engines
  class Pdf < Base
    url %r{\.pdf\z}

    def summarizable?(header)
      if header =~ %r{^Content-Length:\s*(\d+)}i
        if $1.to_i > MaxContentLength
          raise Nop, "Exceed MaxContentLength: #{$1.to_i} bytes"
        end
      end
      header =~ %r{^Content-Type:.*application/pdf}i
    end

    def preprocess_content(content, header)
      pdftohtml(content)
    end

    def pdftohtml(content)
      pdftotext_options = ["-enc", "UTF-8", "-q", "-htmlmeta", "-", "-"]
      Open3.popen3(*["pdftotext", pdftotext_options].flatten) {|i,o,e|
        i.write(content)
        i.close
        o.read
      }
    end
  end
end
