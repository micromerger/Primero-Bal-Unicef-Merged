# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# Zip and encrypt a file with a system configured zipper
class ZipService
  class << self
    def zip(file, password)
      zipper.zip(file, password)
    end

    def zipper
      case ENV.fetch('PRIMERO_ZIP_FORMAT', nil)
      when '7z' then Zippers::SevenZip7z
      when 'zip7z' then Zippers::SevenZipZip
      when 'zip' then Zippers::RubyZip
      else
        Zippers::NoZip
      end.new
    end

    def require_password?
      %w[7z zip7z zip].include? ENV.fetch('PRIMERO_ZIP_FORMAT', nil)
    end
  end
end
