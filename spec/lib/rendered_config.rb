# frozen_string_literal: true

# Renders the rsyslog configuration that a catalogue writes to
# 00_simp_pre_logging, so specs can compare it with complete expected files.
#
# Each file starts from the content of its File resource (the seed for files
# created with `replace => false`), and every File_line resource for it is
# then applied the way stdlib's file_line provider would on a fresh node.
module RenderedConfig
  PRE_LOGGING = '/etc/rsyslog.simp.d/00_simp_pre_logging'

  def self.apply_file_line(lines, res)
    match = Regexp.new(res[:match])
    idx = lines.index { |l| match.match?(l) }

    if res[:ensure] == 'absent'
      lines.reject! { |l| match.match?(l) } if res[:match_for_absence]
    elsif idx
      lines[idx] = res[:line] unless res[:replace] == false
    elsif res[:after]
      after = Regexp.new(res[:after])
      aidx = lines.index { |l| after.match?(l) }
      aidx ? lines.insert(aidx + 1, res[:line]) : lines.push(res[:line])
    else
      lines.push(res[:line])
    end
  end

  # @return [Hash{String => String}] file basename => rendered content
  def self.files(catalogue, dir = PRE_LOGGING)
    file_resources = catalogue.resources.select do |r|
      r.type == 'File' && r.title.start_with?("#{dir}/") && r[:ensure] == 'file'
    end
    files = file_resources.to_h { |r| [r.title, (r[:content] || '').lines.map(&:chomp)] }

    catalogue.resources.select { |r| r.type == 'File_line' && files.key?(r[:path]) }.each do |r|
      apply_file_line(files[r[:path]], r)
    end

    files.sort.to_h { |path, lines| [File.basename(path), lines.join("\n") + "\n"] }
  end

  # Parse rsyslog configuration into an ordered list of normalized
  # statements. Multi-line and single-line forms of the same statement
  # normalize the same way, and parameter order within a statement is
  # ignored.
  def self.statements(content)
    stmts = []
    current = nil

    content.each_line(chomp: true) do |raw|
      line = raw.strip
      next if line.empty? || line.start_with?('#')

      if current
        if line == ')'
          stmts << normalize(current[:head], current[:params])
          current = nil
        else
          current[:params] << line
        end
      elsif line.start_with?('$')
        stmts << line
      elsif line.end_with?(')')
        head, *params = line.delete_suffix(')').split(%r{\s+})
        stmts << normalize(head, params)
      else
        current = { head: line, params: [] }
      end
    end

    stmts
  end

  def self.normalize(head, params)
    name, first = head.split('(', 2)
    params = params.dup
    if first.nil? || first.empty?
      key = "#{name}("
    elsif first.start_with?('load=', 'type=')
      key = "#{name}(#{first}"
    else
      key = "#{name}("
      params.unshift(first)
    end
    "#{key} #{params.sort.join(' ')}".strip
  end

  def self.render(catalogue)
    files(catalogue).values.join
  end
end
