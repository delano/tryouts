

module Tryouts
  class Parser
    module ClassMethods


      def extract_text(node, source_code)
        source_code[node.start_byte...node.end_byte].strip
      end

      def extract_node_text(node, source_code)
        # Get the byte range of the node
        start_byte = node.start_byte
        end_byte = node.end_byte

        # Extract text from source code using the byte range
        source_code[start_byte...end_byte]
      end

      def extract_code(code_lines, source)
        code_lines.map do |line|
          source[line.start_byte...line.end_byte]
        end.join("\n")
      end

      def extract_expectation(expect_node, source)
        return nil unless expect_node
        text = source[expect_node.start_byte...expect_node.end_byte]
        text.gsub(/^#\s*=>\s*/, '').strip
      end

      def debug_node(node, source_code, indent = 0)
        prefix = "  " * indent
        puts "#{prefix}Type: #{node.type}"
        puts "#{prefix}Text: #{extract_node_text(node, source_code)}"
        puts "#{prefix}Start Byte: #{node.start_byte}"
        puts "#{prefix}End Byte: #{node.end_byte}"

        # Use fields instead of each_child
        node.fields.each do |field_name, field_node|
          puts "#{prefix}Field: #{field_name}"
          debug_node(field_node, source_code, indent + 1) if field_node
        end

        # Alternatively, for named children of specific fields
        if node.type == 'test_case'
          code_block = node.child_by_field_name('code_block')
          expectation = node.child_by_field_name('expectation')

          if code_block
            puts "#{prefix}Code Block:"
            debug_node(code_block, source_code, indent + 1)
          end

          if expectation
            puts "#{prefix}Expectation:"
            debug_node(expectation, source_code, indent + 1)
          end
        end
      end

      def debug_node_robust(node, source_code, indent = 0)
        prefix = "  " * indent

        # Basic node info
        puts "#{prefix}Type: #{node.type}"
        puts "#{prefix}Text: #{extract_node_text(node, source_code)}"
        puts "#{prefix}Start Byte: #{node.start_byte}"
        puts "#{prefix}End Byte: #{node.end_byte}"

        # Print available methods
        puts "#{prefix}Available methods: #{node.methods.sort}"

        # Try different child access methods
        begin
          child_count = node.child_count
          puts "#{prefix}Child Count: #{child_count}"

          # If child_count exists, try to iterate
          if child_count > 0
            (0...child_count).each do |i|
              child = node.child(i)
              puts "#{prefix}Child #{i}:"
              debug_node(child, source_code, indent + 1)
            end
          end
        rescue => e
          puts "#{prefix}Could not access children: #{e.message}"
        end

        # Try field-based access
        begin
          fields = node.fields
          puts "#{prefix}Fields: #{fields}"

          fields.each do |field_name, field_node|
            puts "#{prefix}Field: #{field_name}"
            debug_node(field_node, source_code, indent + 1) if field_node
          end
        rescue => e
          puts "#{prefix}Could not access fields: #{e.message}"
        end
      end

      def debug_node_tryouts(node, source_code, indent = 0)
        prefix = "  " * indent
        puts "#{prefix}Type: #{node.type}"

        case node.type
        when 'test_case'
          code_block = node.child_by_field_name('code_block')
          expectation = node.child_by_field_name('expectation')

          puts "#{prefix}Code Block:"
          debug_node(code_block, source_code, indent + 1) if code_block

          puts "#{prefix}Expectation:"
          debug_node(expectation, source_code, indent + 1) if expectation

        when 'code_block'
          node.named_children.each do |child|
            debug_node(child, source_code, indent + 1)
          end

        else
          puts "#{prefix}Text: #{extract_node_text(node, source_code)}"
        end
      end

    end

    extend ClassMethods
  end
end
