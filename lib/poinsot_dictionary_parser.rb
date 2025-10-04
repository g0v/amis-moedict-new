class PoinsotDictionaryParser
  def initialize
    @dialect_codes = {
      "Ch" => "國語",
      "S" => "南方話",
      "F" => "鳳林話",
      "T" => "富田語",
      "J" => "日語",
      "Tw" => "閩南語",
      "N" => "北方話",
      "Z" => "撒奇萊雅語",
      "豐濱" => "豐濱",
      "英語" => "英語",
      "玉里" => "玉里",
      "Tingalaw" => "豐濱豐富部落",
      "希伯來語" => "希伯來語",
      "光復鄉" => "光復鄉",
      "希臘文" => "希臘文"
    }

    @results = []
  end

  def parse_line(line)
    return [] if line.strip.empty?

    # Pre-process to extract examples that might be embedded in term part
    # Look for pattern: "term_structure - example_phrase：translation"
    extracted_example = nil
    processed_line = line

    # Pattern: anything - simple_phrase：translation (where simple_phrase doesn't contain = or {})
    if line.match(/^(.+?)\s*-\s*([^：={}]+)：(.+)$/)
      # Check if this looks like an example pattern
      potential_match = line.match(/^(.+?)\s*-\s*([^：={}]+)：(.+)$/)
      if potential_match
        main_part = potential_match[1].strip
        potential_amis = potential_match[2].strip
        potential_zh = potential_match[3].strip

        # Only treat as example if:
        # 1. Main part contains term structure indicators (= or {})
        # 2. Potential amis is simple (no complex punctuation)
        # 3. Main part doesn't already have a colon
        if !main_part.include?("：") &&
           (main_part.include?(" = ") || main_part.include?("{")) &&
           !potential_amis.include?("=") &&
           !potential_amis.include?("{") &&
           potential_amis.split.length <= 4 # Simple phrase

          extracted_example = { amis: potential_amis, zh: potential_zh }
          processed_line = main_part + "：" # Add empty description
        end
      end
    end

    # Split on the main colon separator
    parts = processed_line.split("：", 2)
    return [] if parts.length < 2

    term_part = parts[0].strip
    description_part = parts[1].strip

    # Check for empty term part
    if term_part.empty?
      raise ArgumentError, "Empty term part in line: #{line.inspect}"
    end

    # Check if description part contains synonyms (indicated by = signs)
    # This needs to be handled specially for cases like example 12
    # Only apply this logic when:
    # - Description part has = but no - (synonyms, not examples)
    # - Term part has - but no = (stem relationship, not synonyms in term part)
    if description_part.include?(" = ") && !description_part.include?(" - ") &&
       term_part.include?(" - ") && !term_part.include?(" = ")
      # Split description part into actual description and synonyms
      desc_synonym_parts = description_part.split(" = ").map(&:strip)
      actual_description = desc_synonym_parts[0]
      synonym_parts = desc_synonym_parts[1..-1]

      # Parse the term part normally
      term_info = parse_term_part(term_part)

      # Add synonyms from description part to term structure
      synonym_parts.each do |syn_part|
        term, dialects = extract_term_and_dialects(syn_part)
        term_info[:terms] << term if term
        term_info[:dialects][term] = dialects if term && dialects && !dialects.empty?
      end

      # Create synonym groups including all terms
      all_terms = term_info[:terms]
      term_info[:synonyms_groups] = [ all_terms ] if all_terms.length > 1

      # Create description info with just the actual description
      desc_info = {
        descriptions: [ actual_description ],
        examples: [],
        parenthetical_part: nil
      }

      # Add extracted example if any
      desc_info[:examples] << extracted_example if extracted_example

      # Generate results
      return generate_results(term_info, desc_info)
    end

    # Regular parsing for other cases
    term_info = parse_term_part(term_part)
    desc_info = parse_description_part(description_part)

    # Add extracted example if any
    desc_info[:examples] << extracted_example if extracted_example

    generate_results(term_info, desc_info)
  end

  private

    def parse_term_part(term_part)
      parse_term_structure(term_part)
    end

  def parse_term_structure(term_part)
    result = {
      stems: [],
      terms: [],
      synonyms_groups: [],
      dialects: {},
      stem_derived_terms: [] # Track which terms are directly derived from stems
    }

    # Split by " - " to handle stem relationships and " = " for synonyms
    # First handle the case where we have both stems and synonyms
    if term_part.include?(" - ") && term_part.include?(" = ")
      # Pattern like: "stem - term1 {dialect} = term2" or "stem - {dialect} = term2" or "stem - term - {dialect} = synonym"
      dash_parts = term_part.split(" - ", 2)
      stem = dash_parts[0].strip
      rest = dash_parts[1].strip

      # Check if the rest starts with just dialect codes followed by =
      dialect_only_match = rest.match(/^\s*(\{[^}]+\})\s*=\s*(.+)$/)
      if dialect_only_match
        # Pattern: "stem - {dialect} = synonyms"
        # The dialect applies to the stem, not a separate term
        dialect_part = dialect_only_match[1]
        synonyms_part = dialect_only_match[2].strip

        # Extract dialect for the stem
        dialects = extract_dialects(dialect_part)

        # Add stem as main term with dialect
        result[:terms] << stem
        result[:dialects][stem] = dialects if dialects && !dialects.empty?

        # Parse synonyms - just take the main synonym term, not additional words
        synonym_terms = synonyms_part.split(/[\s=]+/).reject(&:empty?).reject { |t| t.match(/[{}]/) }
        # Only take the first term as synonym to avoid parsing structural elements
        if synonym_terms.length > 0
          result[:terms] << synonym_terms[0]
        end

        # Create synonym group
        result[:synonyms_groups] = [ result[:terms] ] if result[:terms].length > 1
        return result
      end

      # Check for pattern: "stem - term - {dialect} = synonym"
      term_dialect_synonym_match = rest.match(/^(.+?)\s*-\s*(\{[^}]+\})\s*=\s*(.+)$/)
      if term_dialect_synonym_match
        term_part_inner = term_dialect_synonym_match[1].strip
        dialect_part = term_dialect_synonym_match[2]
        synonyms_part = term_dialect_synonym_match[3].strip

        # Extract dialect
        dialects = extract_dialects(dialect_part)

        # Add stem
        result[:stems] << stem

        # Add derived term with dialect
        result[:terms] << term_part_inner
        result[:stem_derived_terms] << term_part_inner
        result[:dialects][term_part_inner] = dialects if dialects && !dialects.empty?

        # Parse synonyms
        synonym_terms = synonyms_part.split(/[\s=]+/).reject(&:empty?).reject { |t| t.match(/[{}]/) }
        if synonym_terms.length > 0
          result[:terms] << synonym_terms[0]
        end

        # Create synonym group with derived term and synonym
        result[:synonyms_groups] = [ [ term_part_inner, synonym_terms[0] ].compact ] if synonym_terms.length > 0
        return result
      end

      # Check for pattern: "stem - {dialect} - term = synonym"
      dialect_term_synonym_match = rest.match(/^(\{[^}]+\})\s*-\s*(.+?)\s*=\s*(.+)$/)
      if dialect_term_synonym_match
        dialect_part = dialect_term_synonym_match[1]
        term_part_inner = dialect_term_synonym_match[2].strip
        synonyms_part = dialect_term_synonym_match[3].strip

        # Extract dialect
        dialects = extract_dialects(dialect_part)

        # Add stem
        result[:stems] << stem

        # Add derived term with dialect
        result[:terms] << term_part_inner
        result[:stem_derived_terms] << term_part_inner
        result[:dialects][term_part_inner] = dialects if dialects && !dialects.empty?

        # Parse synonyms
        synonym_terms = synonyms_part.split(/[\s=]+/).reject(&:empty?).reject { |t| t.match(/[{}]/) }
        if synonym_terms.length > 0
          result[:terms] << synonym_terms[0]
        end

        # Create synonym group with derived term and synonym
        result[:synonyms_groups] = [ [ term_part_inner, synonym_terms[0] ].compact ] if synonym_terms.length > 0
        return result
      end

      # Original logic for other cases
      result[:stems] << stem

      # Parse the rest for synonyms and dialects
      synonym_info = parse_synonyms_and_dialects(rest)

      synonym_info[:terms].each_with_index do |term, index|
        next if term.nil? # Skip nil terms
        result[:terms] << term
        if synonym_info[:dialects][index] && !synonym_info[:dialects][index].empty?
          result[:dialects][term] = synonym_info[:dialects][index]
        end

        # Only the first term is stem-derived
        if index == 0
          result[:stem_derived_terms] << term
        end
      end
      result[:synonyms_groups] = [ synonym_info[:terms].compact ] if synonym_info[:terms].compact.length > 1

    elsif term_part.include?(" - ")
      # Pattern like: "stem - term1 - term2" or "stem - term {dialect}" or "term - {dialect}"
      parts = term_part.split(" - ")
      first_part = parts[0].strip

      # Check if this is just "term - {dialect}" pattern
      if parts.length == 2
        second_part = parts[1].strip
        # If the second part becomes empty after removing dialect codes,
        # then this is a "term - {dialect}" pattern, not a stem-term relationship
        clean_second_part = second_part.gsub(/\s*\{[^}]+\}/, "").strip

        if clean_second_part.empty?
          # This is "term - {dialect}" pattern
          combined_term_with_dialect = "#{first_part} #{second_part}".strip
          term, dialects = extract_term_and_dialects(combined_term_with_dialect)
          result[:terms] << term if term
          result[:dialects][term] = dialects if term && dialects && !dialects.empty?
          return result
        end
      end

      # Regular stem-term relationship processing
      stem = first_part
      result[:stems] << stem

      terms_part = parts[1..-1].join(" - ")
      if terms_part.include?(" = ")
        # Handle case like "stem - term1 = term2"
        synonym_info = parse_synonyms_and_dialects(terms_part)
        synonym_info[:terms].each_with_index do |term, index|
          next if term.nil? # Skip nil terms
          result[:terms] << term
          if synonym_info[:dialects][index] && !synonym_info[:dialects][index].empty?
            result[:dialects][term] = synonym_info[:dialects][index]
          end

          # Only the first term is stem-derived
          if index == 0
            result[:stem_derived_terms] << term
          end
        end
        result[:synonyms_groups] = [ synonym_info[:terms].compact ] if synonym_info[:terms].compact.length > 1
      else
        # Multiple terms from same stem: "stem - term1 - term2"
        parts[1..-1].each do |term_with_dialect|
          term_text = term_with_dialect.strip

          # Check if this contains comma-separated terms
          if term_text.include?(",")
            # Split by comma and process each term
            comma_separated_terms = term_text.split(",").map(&:strip)
            comma_separated_terms.each do |single_term_text|
              single_term_text = single_term_text.strip
              next if single_term_text.empty?

              # Check if this is just parenthetical content: "(stem)"
              if single_term_text.match(/^\s*\(([^)]+)\)\s*$/)
                # Pattern: "term - (stem)" - parenthetical content is the actual stem
                stem_content = single_term_text.match(/^\s*\(([^)]+)\)\s*$/)[1].strip
                actual_term = stem # The original "stem" is actually the term

                # Clear previous data and set correct structure
                result[:stems] = [ stem_content ]
                result[:terms] = [ actual_term ]
                result[:stem_derived_terms] = [ actual_term ]
              else
                # Regular term processing
                term, dialects = extract_term_and_dialects(single_term_text)
                next if term.nil? # Skip nil terms
                result[:terms] << term
                result[:stem_derived_terms] << term # All are stem-derived in this case
                result[:dialects][term] = dialects if dialects && !dialects.empty?
              end
            end

            # Create synonym relationships between all comma-separated terms
            valid_terms = comma_separated_terms.map { |t|
              term, _ = extract_term_and_dialects(t.strip)
              term
            }.compact

            if valid_terms.length > 1
              result[:synonyms_groups] << valid_terms
            end

          # Check if this is just parenthetical content: "(stem)"
          elsif term_text.match(/^\s*\(([^)]+)\)\s*$/)
            # Pattern: "term - (stem)" - parenthetical content is the actual stem
            stem_content = term_text.match(/^\s*\(([^)]+)\)\s*$/)[1].strip
            actual_term = stem # The original "stem" is actually the term

            # Clear previous data and set correct structure
            result[:stems] = [ stem_content ]
            result[:terms] = [ actual_term ]
            result[:stem_derived_terms] = [ actual_term ]

          # Check for parenthetical content with other text: "term (synonym)"
          elsif term_text.match(/^(.+?)\s*\(([^)]+)\)\s*(.*)$/)
            parenthetical_match = term_text.match(/^(.+?)\s*\(([^)]+)\)\s*(.*)$/)
            main_part = parenthetical_match[1].strip
            parenthetical_content = parenthetical_match[2].strip
            remaining_part = parenthetical_match[3].strip

            # Pattern: "stem - term (synonym)" - parenthetical content is a synonym
            combined_main = "#{main_part} #{remaining_part}".strip
            main_term, main_dialects = extract_term_and_dialects(combined_main)

            # Extract synonym (assume no dialects in synonym for now)
            synonym_term, synonym_dialects = extract_term_and_dialects(parenthetical_content)

            if main_term && synonym_term
              # Add both terms
              result[:terms] << main_term
              result[:terms] << synonym_term
              result[:stem_derived_terms] << main_term # Only main term is stem-derived

              # Add dialects
              result[:dialects][main_term] = main_dialects if main_dialects && !main_dialects.empty?
              result[:dialects][synonym_term] = synonym_dialects if synonym_dialects && !synonym_dialects.empty?

              # Create synonym relationship
              result[:synonyms_groups] << [ main_term, synonym_term ]
            end
          else
            # Original logic
            term, dialects = extract_term_and_dialects(term_text)
            next if term.nil? # Skip nil terms
            result[:terms] << term
            result[:stem_derived_terms] << term # All are stem-derived in this case
            result[:dialects][term] = dialects if dialects && !dialects.empty?
          end
        end
      end

    elsif term_part.include?(" = ")
      # Pattern like: "term1 = term2 = term3"
      synonym_info = parse_synonyms_and_dialects(term_part)
      synonym_info[:terms].each_with_index do |term, index|
        next if term.nil? # Skip nil terms
        result[:terms] << term
        if synonym_info[:dialects][index] && !synonym_info[:dialects][index].empty?
          result[:dialects][term] = synonym_info[:dialects][index]
        end
      end
      result[:synonyms_groups] = [ synonym_info[:terms].compact ] if synonym_info[:terms].compact.length > 1

    else
      # Single term, possibly with dialect
      term, dialects = extract_term_and_dialects(term_part)
      result[:terms] << term if term
      result[:dialects][term] = dialects if term && dialects && !dialects.empty?
    end

    result
  end

  def parse_synonyms_and_dialects(text)
    # Split by " = " and extract dialects from each part
    parts = text.split(" = ")
    terms = []
    dialects = []

    parts.each do |part|
      part = part.strip

      # Check if this part contains parenthetical comma-separated terms
      # Pattern: "term (term1, term2, term3)"
      parenthetical_match = part.match(/^(.+?)\s*\(([^)]+)\)\s*(.*)$/)
      if parenthetical_match
        main_term = parenthetical_match[1].strip
        parenthetical_content = parenthetical_match[2].strip
        remaining_part = parenthetical_match[3].strip

        # Add the main term
        if !main_term.empty?
          main_term_with_remaining = "#{main_term} #{remaining_part}".strip
          term, term_dialects = extract_term_and_dialects(main_term_with_remaining)
          terms << term
          dialects << term_dialects
        end

        # Add the comma-separated terms from parentheses
        parenthetical_terms = parenthetical_content.split(",").map(&:strip)
        parenthetical_terms.each do |pterm|
          term, term_dialects = extract_term_and_dialects(pterm)
          terms << term
          dialects << term_dialects
        end
      else
        # Regular term processing
        term, term_dialects = extract_term_and_dialects(part)
        terms << term # Can be nil
        dialects << term_dialects
      end
    end

    { terms: terms, dialects: dialects }
  end

  def extract_term_and_dialects(text)
    # Extract dialects in format {A}{B}{C}
    dialect_matches = text.scan(/\{([^}]+)\}/)
    dialects = dialect_matches.flatten.map { |code| @dialect_codes[code] }.compact

    # Remove dialect codes from term
    clean_term = text.gsub(/\s*\{[^}]+\}/, "").strip

    # If term is empty after removing dialect codes, return nil for term
    if clean_term.empty?
      return [ nil, dialects ]
    end

    [ clean_term, dialects ]
  end

  def extract_dialects(dialect_part)
    dialect_matches = dialect_part.scan(/\{([^}]+)\}/)
    dialect_matches.flatten.map { |code| @dialect_codes[code] }.compact
  end

  def parse_description_part(description_part)
    result = {
      descriptions: [],
      examples: [],
      parenthetical_part: nil
    }

    # First check for multiple examples with quotes (highest priority)
    # Pattern: "description - "example1" - "example2""
    if description_part.include?(" - “") && description_part.scan(/“[^“]*”/).length >= 2
      # Split by " - " to get parts
      parts = description_part.split(" - ")
      desc_text = parts[0].strip
      example_parts = parts[1..-1]

      # Check if we have quote patterns in the example parts
      quote_examples_found = false
      example_parts.each do |part|
        # Pattern: "amis"(reference)"zh"
        pattern_match = part.match(/^“([^“()]+)”\(([^)]+)\)“([^“]+)”$/)
        if pattern_match
          quote_examples_found = true
          amis_example = pattern_match[1]
          zh_translation = "(#{pattern_match[2]})#{pattern_match[3]}"
          result[:examples] << { amis: amis_example, zh: zh_translation }
        end
      end

      if quote_examples_found
        result[:descriptions] = parse_descriptions(desc_text)
        return result
      end
    end

    # Check for simple examples BEFORE parenthetical examples
    example_match = description_part.match(/^(.+?)\s*-\s*([^：]+)：(.+)$/)
    if example_match
      desc_text = example_match[1].strip
      amis_example = example_match[2].strip
      zh_translation = example_match[3].strip

      result[:descriptions] = parse_descriptions(desc_text)
      result[:examples] << { amis: amis_example, zh: zh_translation }
      return result
    end

    # Check for examples with parenthetical reference (no quotes)
    # Pattern: "description - amis_text (reference) chinese_translation"
    parenthetical_example_match = description_part.match(/^(.+?)\s*-\s*(.+?)\s*\(([^)]+)\)\s*(.+)$/)
    if parenthetical_example_match && !description_part.include?("“")
      desc_text = parenthetical_example_match[1].strip
      amis_example = parenthetical_example_match[2].strip
      reference = parenthetical_example_match[3].strip
      zh_translation = "(#{reference}) #{parenthetical_example_match[4].strip}"

      result[:descriptions] = parse_descriptions(desc_text)
      result[:examples] << { amis: amis_example, zh: zh_translation }
      return result
    end

    # Parse descriptions and check for parenthetical content with dialect
    # Split by ；and check if last part has parenthetical + dialect pattern
    desc_parts = description_part.split("；").map(&:strip)

    # Check if the last part has parenthetical content with dialect
    if desc_parts.length > 1
      last_part = desc_parts.last
      # Pattern: (parenthetical)additional_text {dialect}
      parenthetical_match = last_part.match(/^\(([^)]+)\)(.+?)\s*(\{[^}]+\})$/)

      if parenthetical_match
        # Found parenthetical with dialect in last part
        parenthetical_part = parenthetical_match[1].strip
        additional_text = parenthetical_match[2].strip
        dialect_part = parenthetical_match[3]

        # Full description is parenthetical + additional text
        full_desc = "(#{parenthetical_part})#{additional_text}"

        # Main descriptions are all parts except the last one
        result[:descriptions] = desc_parts[0..-2]

        # Extract dialects and store parenthetical info
        if dialect_part
          dialects = extract_dialects(dialect_part)
          result[:parenthetical_part] = {
            description: full_desc,
            dialects: dialects
          }
        end

        return result
      end
    end

    # No parenthetical content, just regular descriptions
    if description_part.include?(" = ")
      result[:descriptions] = description_part.split(" = ").map(&:strip)
    else
      result[:descriptions] = desc_parts
    end

    result
  end

  def parse_descriptions(desc_text)
    # Split descriptions by "；" and handle "=" for alternative descriptions
    if desc_text.include?(" = ")
      desc_text.split(" = ").map(&:strip)
    else
      desc_text.split("；").map(&:strip)
    end
  end

  def generate_results(term_info, desc_info)
    results = []

    # Handle parenthetical entries from term part first
    if term_info[:parenthetical]
      # Create entry for the main term with parenthetical description
      main_term = term_info[:terms].first
      if main_term
        # Only assign stem if this term is stem-derived
        stem_to_assign = if term_info[:stem_derived_terms].include?(main_term)
                           term_info[:stems].first
                         else
                           nil
                         end

        results << create_entry(
          term: main_term,
          dialects: term_info[:parenthetical][:dialects],
          descriptions: [ term_info[:parenthetical][:description] ],
          stem: stem_to_assign
        )
      end

      # Create entries for main descriptions (excluding parenthetical)
      term_info[:terms].each do |term|
        next unless term # Skip nil terms
        next if term_info[:dialects][term] # Skip terms that already have dialects from parenthetical

        # Only assign stem if this term is stem-derived
        stem_to_assign = if term_info[:stem_derived_terms].include?(term)
                           term_info[:stems].first
                         else
                           nil
                         end

        results << create_entry(
          term: term,
          descriptions: desc_info[:descriptions],
          examples: desc_info[:examples],
          synonyms: get_synonyms_for_term(term, term_info[:synonyms_groups]),
          stem: stem_to_assign
        )
      end
    else
      # Regular processing - handle parenthetical from description part
      if desc_info[:parenthetical_part]
        # Create main entry with main descriptions
        term_info[:terms].each do |term|
          next unless term # Skip nil terms

          if !desc_info[:descriptions].empty?
            # Only assign stem if this term is stem-derived
            stem_to_assign = if term_info[:stem_derived_terms].include?(term)
                               term_info[:stems].first
                             else
                               nil
                             end

            entry = create_entry(
              term: term,
              descriptions: desc_info[:descriptions],
              examples: desc_info[:examples],
              dialects: term_info[:dialects][term],
              synonyms: get_synonyms_for_term(term, term_info[:synonyms_groups]),
              stem: stem_to_assign
            )
            results << entry
          end

          # Create separate entry for parenthetical part
          stem_to_assign = if term_info[:stem_derived_terms].include?(term)
                             term_info[:stems].first
                           else
                             nil
                           end

          parenthetical_entry = create_entry(
            term: term,
            descriptions: [ desc_info[:parenthetical_part][:description] ],
            dialects: desc_info[:parenthetical_part][:dialects],
            stem: stem_to_assign
          )
          results << parenthetical_entry
        end
      else
        # No parenthetical content - regular processing
        term_info[:terms].each do |term|
          next unless term # Skip nil terms

          # Only assign stem if this term is stem-derived
          stem_to_assign = if term_info[:stem_derived_terms].include?(term)
                             term_info[:stems].first
                           else
                             nil
                           end

          entry = create_entry(
            term: term,
            descriptions: desc_info[:descriptions],
            examples: desc_info[:examples],
            dialects: term_info[:dialects][term],
            synonyms: get_synonyms_for_term(term, term_info[:synonyms_groups]),
            stem: stem_to_assign
          )
          results << entry
        end
      end
    end

    results
  end

  def create_entry(term:, descriptions: [], examples: [], dialects: nil, synonyms: nil, stem: nil)
    # Check for empty term
    if term.nil? || term.strip.empty?
      raise ArgumentError, "Cannot create entry with empty term"
    end

    entry = {}
    entry[:stem] = stem.gsub("’", "'") if stem && stem != term
    entry[:term] = term.gsub("’", "'")
    entry[:dialects] = dialects if dialects && !dialects.empty?

    # Handle descriptions - set to empty string if no meaningful description
    if !descriptions.first.nil? && !descriptions.first.strip.empty?
      entry[:description] = descriptions.map { |d| d.gsub("’", "'") }
    else
      entry[:description] = [ "" ]
    end

    entry[:examples] = examples.map { |e| { amis: e[:amis].gsub("’", "'"), zh: e[:zh] } } if examples && !examples.empty?
    entry[:synonyms] = synonyms.map { |s| s.gsub("’", "'") } if synonyms && !synonyms.empty?

    entry
  end

  def get_synonyms_for_term(term, synonym_groups)
    synonym_groups.each do |group|
      if group.include?(term)
        return group.reject { |t| t == term }
      end
    end
    nil
  end
end
