SonataApp.controller('SideBarController', function($scope, $routeParams, $location, $http) {

    
 	$scope.$on('$includeContentLoaded', function(event) {
      	$(".button-collapse").sideNav();
		$('.collapsible').collapsible();
		console.log('SideBar');
    });


    });


