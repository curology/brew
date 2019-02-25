require "json"
require "cask/installer"

module Cask
  class Cmd
    class Info < AbstractCommand
      option "--json=VERSION", :json

      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        if json == "v1"
          puts JSON.generate(casks.map(&:to_h))
        else
          casks.each do |cask|
            odebug "Getting info for Cask #{cask}"
            self.class.info(cask)
          end
        end
      end

      def self.help
        "displays information about the given Cask"
      end

      def self.get_info(cask)
        <<~EOS.chomp
          #{title_info(cask)}
          #{Formatter.url(cask.homepage) if cask.homepage}
          #{installation_info(cask)}
          #{repo_info(cask)}#{name_info(cask)}#{language_info(cask)}#{artifact_info(cask)}#{Installer.print_caveats(cask)}
        EOS
      end

      def self.info(cask)
        puts get_info(cask)
      end

      def self.title_info(cask)
        title = "#{cask.token}: #{cask.version}"
        title += " (auto_updates)" if cask.auto_updates
        title
      end

      def self.formatted_url(url)
        "#{Tty.underline}#{url}#{Tty.reset}"
      end

      def self.installation_info(cask)
        install_info = ""
        if cask.installed?
          cask.versions.each do |version|
            versioned_staged_path = cask.caskroom_path.join(version)
            install_info << versioned_staged_path.to_s
                            .concat(" (")
                            .concat(
                              if versioned_staged_path.exist?
                              then versioned_staged_path.abv
                              else Formatter.error("does not exist")
                              end,
                            ).concat(")")
            install_info << "\n"
          end
          return install_info.strip
        else
          "Not installed"
        end
      end

      def self.name_info(cask)
        <<~EOS
          #{ohai_title((cask.name.size > 1) ? "Names" : "Name")}
          #{cask.name.empty? ? Formatter.error("None") : cask.name.join("\n")}
        EOS
      end

      def self.language_info(cask)
        return if cask.languages.empty?

        <<~EOS
          #{ohai_title("Languages")}
          #{cask.languages.join(", ")}
        EOS
      end

      def self.repo_info(cask)
        return if cask.tap.nil?

        url = if cask.tap.custom_remote? && !cask.tap.remote.nil?
          cask.tap.remote
        else
          "#{cask.tap.default_remote}/blob/master/Casks/#{cask.token}.rb"
        end

        "From: #{Formatter.url(url)}\n"
      end

      def self.artifact_info(cask)
        cask.artifacts.each do |artifact|
          next unless artifact.respond_to?(:install_phase)
          next unless DSL::ORDINARY_ARTIFACT_CLASSES.include?(artifact.class)

          return <<~EOS
            #{ohai_title("Artifacts")}
            #{artifact}
          EOS
        end
      end
    end
  end
end
