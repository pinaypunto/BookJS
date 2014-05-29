module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    meta:
      builds  : 'dist',
      banner  : '/* <%= pkg.name %> v<%= pkg.version %> - <%= grunt.template.today("yyyy/m/d") %>\n' +
              '   <%= pkg.homepage %>\n' +
              '   Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>' +
              ' - Licensed <%= _.pluck(pkg.license, "type").join(", ") %> */\n'

    source:

      coffee: [
        'source/lib/*.coffee'
        'source/book.coffee'
        'source/page.coffee'
        'source/events.coffee'
      ]
      style: [
        'source/style/book.styl'
      ]

    stylus:
      book:
        options: compress: true, import: [ '__init', '__theme']
        files: '<%= meta.builds %>/<%= pkg.name %>.css': '<%= source.style %>'
    
    concat:
      book:
        files: 
          '<%= meta.builds %>/<%= pkg.name %>.coffee': ['<%= source.coffee %>']

    coffee:
      book: files: '<%= meta.builds %>/<%= pkg.name %>.debug.js': '<%= meta.builds %>/<%= pkg.name %>.coffee'

    uglify:
      book: files: '<%=meta.builds%>/<%=pkg.name%>.js': '<%=meta.builds%>/<%=pkg.name%>.debug.js'


    watch:
      book:
        files: ['<%= source.coffee %>']
        tasks: ['concat', 'coffee', 'uglify']
      styles:
        files: ['<%= source.style %>']
        tasks: ['stylus']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-watch'


  grunt.registerTask 'default', ['stylus', 'concat', 'coffee', 'uglify']
