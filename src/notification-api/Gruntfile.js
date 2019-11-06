module.exports = function (grunt) {

    require('load-grunt-tasks')(grunt); // <-- uses `load-grunt-tasks`

  grunt.initConfig({
    shell: {
      npm_pack: {
        command: 'npm run pack --silent',
      }
    }
  });

  grunt.registerTask('build', [ 'shell:npm_pack' ]);
  
  };