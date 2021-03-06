require 'zip'
require 'zip/filesystem'
require 'json'
require 'bindata'

module Pebble
  module Bin
    class Version < BinData::Record
      uint8 :major
      uint8 :minor
    end

    class AppInfo < BinData::Record
      endian :big

      string  :header, length: 8, asserted_value: "PBLAPP\0\0"
      version :struct_version
      version :sdk_version
      version :app_version
      uint16  :bin_size
      uint32  :bin_offset
      uint32  :crc
      string  :name, length: 32, trim_padding: true
      string  :company, length: 32, trim_padding: true
      uint32  :icon_resource_id
      uint32  :sym_table_addr
      uint32  :flags
      uint32  :reloc_list_start
      uint32  :num_reloc_entries
      array   :uuid, type: :uint8, initial_length: 16
    end
  end

  class Bundle
    def initialize(path)
      @path = path
    end

    attr_reader :path


    def manifest
      @manifest ||= JSON.parse(zip.file.read("manifest.json"))
    end

    def header
      @header ||= Bin::AppInfo.read(bin)
    end

    alias :app_metadata :header


    def is_firmware?
      manifest.has_key?("firmware")
    end

    def is_app?
      manifest.has_key?("application")
    end

    def has_resources?
      manifest.has_key?("resources")
    end

    def firmware_info
      manifest["firmware"]
    end

    def app_info
      manifest["application"]
    end

    def resources_info
      manifest["resources"]
    end

    def uuid_hex
      header.uuid.map{ |byte| byte.to_i.to_s(16) }
    end

    def uuid_hex_string
      header.uuid.map{ |byte| "%02X" % byte.to_i }.join(' ')
    end

    def close
      zip.close
      @zip = nil
    end


    private
    def zip
      @zip ||= Zip::File.open(path)
    end

    def bin
      @bin ||= @zip.file.read("pebble-app.bin")
    end
  end
end

