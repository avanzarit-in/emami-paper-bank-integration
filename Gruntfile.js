'use strict';

module.exports = function (grunt) {
  require('load-grunt-tasks')(grunt);
  require('time-grunt')(grunt);
  grunt.initConfig({

    dirs: {
      // configurable paths
      dist: 'dist',

      //child projects
      notificationApi: 'src/notification-api',
      validationApi: 'src/validation-api'
    },
    
    hub: {
      client: {
        src: ['<%= dirs.notificationApi %>/Gruntfile.js'],
        tasks: ['build'],
      },
      server: {
        src: ['<%= dirs.validationApi %>/Gruntfile.js'],
        tasks: ['build'],
      },
    }
  });



  grunt.registerTask('npmInstallSubprojects', [
    'shell:npmInstallServer',
    'shell:npmInstallClient'
  ]);

  grunt.registerTask('buildSubprojects', [
    'hub:server',
    'hub:client'
  ]);


  grunt.registerTask('default', [
    'buildSubprojects'
  ]);
}
