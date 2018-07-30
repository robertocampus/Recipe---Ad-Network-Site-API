<cfcomponent extends="taffyAPI.base" taffy:uri="/controller/" hint="controller for site">

	<cffunction name="POST" access="public" returntype="Struct" hint="">
		<cfargument name="functionName" type="string" required="true" hint="Function name depends upon the form action.">
		<cfargument name="attributes"   type="string" required="true" hint="User's Form data submitted from front-end.">
		<cfargument name="filePath"   	type="string" required="false" hint="file need to uploaded">
		<cfargument name="cgi"	 	    type="struct" required="no" default="#StructNew()#" hint="CGI vars Structure">		

		<cfset structAppend( arguments, deserializeJson( arguments.attributes ) )>

		<cfset result = structNew() >
		<cfset result['error'] = false >
		<cfset result['errors'] = "" >
		<cfset result['errorsforlog'] = "" >
		<cfset result['message'] = "">

		<cfswitch expression="#arguments.functionName#">

			<!--- METHOD START:: doSignUp --->
			<cfcase value="doSignUp">
				<!--- // START: form validation --->

				<cfscript>
			
				param name="arguments.email"			type="string" default="";				
				param name="arguments.firstName" 		type="string" default="";
				param name="arguments.lastName" 		type="string" default="";
				param name="arguments.password" 		type="string" default="";
				param name="arguments.passwordConfirm" 	type="string" default="";
				param name="arguments.username" 		type="string" default="";
				param name="arguments.gender" 			type="string" default="";
				param name="arguments.countryID" 		type="string" default="";
				param name="arguments.stateID" 	 		type="string" default="";
				param name="arguments.city" 	 		type="string" default="";					
				param name="arguments.about" 	 		type="string" default="";
				param name="arguments.secret"			type="string" default="";
				param name="arguments.response"			type="string" default="";
				param name="arguments.roleID"			type="string" default="0";
				param name="arguments.isreCaptcha"		type="string" default="0";
				
				if( arguments.isreCaptcha NEQ 1 ){

					http = new http();

					http.settimeout(3000);

					http.seturl( 'https://www.google.com/recaptcha/api/siteverify' );
					http.setMethod( 'POST' );

					http.addParam(type="formField", name="secret", value="#arguments.secret#");
					http.addParam(type="formField", name="response", value="#arguments.response#");

					returnData = http.send().getPrefix();

					captchaValidation = deserializeJson(returnData.filecontent);

					// Captcha Validation

					if( NOT captchaValidation.success ){
						result['errors'] 		= listAppend(result['errors'],"reCaptcha");
						result['errorsforlog'] 	= listAppend(result['errorsforlog'],"Error While reCaptcha validation.");
					}
				}


				// verify if provided email is valid
				if ( NOT isValid("email", arguments.email) ) {
					result['errors'] = listAppend(result['errors'], "email");
					result['errorsforlog'] = listAppend(result['errorsforlog'], "email: #arguments.email#");
				}

				// verifying if valid input or not?
				if ( ListLen(result['errors']) EQ 0 ) {					

					// verify if user's email already in USE
					local.attributes = structNew();
					local.attributes.filters.SearchUserEmail = arguments.email;

					checkUserMail = httpRequest( methodName = 'GET', endPointOfURL = '/Users/', timeout = 3000, parameters = local.attributes );

					if( checkUserMail.status_code EQ '200' ) {

						result['errors'] = listAppend(result['errors'], "user_mailNA");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "user_mailNA: #arguments.email#");
						result.message = application.messages['controller_post_dosignup_emailexist'];

					}

				}
	 
				// start: any errors?
				if ( ListLen(result['errors']) GT 0 ) { 
					result['error'] = true; 
				
					// Log Invalid Registration Input
					local.logAction = logAction( actionID = 55, extra = result['errorsforlog'], cgi = arguments.cgi );						
					
					return representationOf(result).withStatus(401);
				
				} else {

					// 50, 'Registered', 'Registration : Successfull', 1
					local.logAction = logAction( actionID = 50, cgi = arguments.cgi );						
					
					// generate new activation code
					result.userConfirmationCode  = left(CreateUUID(), 25);
				
					// creat user account					

					/* http Call to insert users*/
					structClear(local.attributes);
					local.attributes.username				= arguments.username;
					local.attributes.userEmail 				= arguments.email;
					local.attributes.userFirstName 			= arguments.firstName;
					local.attributes.userLastName			= arguments.lastName;	 
					local.attributes.userPassword			= arguments.password;
					local.attributes.userGender				= arguments.gender;
					local.attributes.userCountryID			= val(arguments.countryID);
					local.attributes.userStateID			= arguments.stateID;
					local.attributes.userCity				= arguments.city;
					local.attributes.userAbout				= arguments.about;
					local.attributes.userConfirmationCode	= result.userConfirmationCode;
					local.attributes.roleID					= arguments.roleID;
					local.attributes.isConfirmed			= 0;
					// local.attributes.cgi 				= arguments.cgi;

					local.addUser = httpRequest( methodName = 'POST', endPointOfURL = '/Users/', timeout = 3000, parameters = local.attributes );

					// start: user account added?
					if ( local.addUser.status_code NEQ '200' ) {
						
						result.message  = application.messages['controller_post_dosignup_error'];
						result.status  = false;
						
						return representationOf(result).withStatus(400);						
					
					} else {
						
						local.data = deserializeJson(local.addUser.filecontent);
						result.dataset = local.data.dataset;

						// user created successfully - create blog record next
	 					
						// Insert User Preferences
						result.insertPreferences = application.accountObj.insertPreferences( userID = result.dataset[1].userID );
						
						// Insert User META
						result.insertUserMeta = application.accountObj.insertUserMeta( userID = result.dataset[1].userID );
						
						// email user with activate account email
						structClear(local.attributes);
						local.email.attributes = "{
													'emailID'  = '637',
													'TOuserID' = '#result.dataset[1].userID#',
													'CCuserID' = '1',
													'userID'   = '1',
													'blogID'   = '0',
													'insertConfirmationCode' = '1'
													}";

						local.email.notificationName = 'sendEmailToUser';

						local.sendEmail  = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );
						
						result.sendEmail = deserializeJson(local.sendEmail.filecontent);
						
						result.message  = application.messages['controller_post_dosignup_success'];
						result.status   = true;

						return representationOf(result).withStatus(200);
						
					}
					// end: user account added?			
				}
				// end: any errors?

				</cfscript>
					
			</cfcase>
			<!--- METHOD END:: doSignUp --->
				
			<!--- METHOD START:: doComment --->
			<cfcase value="doComment">
	
				<!--- // START: form validation --->
				<cfscript>
				// setting form fields default params
	  			param name="arguments.auth_token" 	type="string"  default="";
	  			param name="arguments.userID" 		type="numeric" default="0";
	  			param name="arguments.commentText" 	type="string"  default="";
	  			param name="arguments.entityID" 	type="numeric" default="0";
	  			param name="arguments.entityTypeID" type="numeric" default="0";

	  			arrayOfRequiredArguments = listToArray("auth_token,userID,entityID,entityTypeID,commentText");
	
			  	for( element in arrayOfRequiredArguments ) {
			  		
			  		if( NOT len(trim(arguments[element])) OR arguments[element] EQ '0' ) {
			  			result['errors'] = listAppend(result['errors'], element);
			  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
			  		}

			  	}

			  	// start: user logged in?
	  			if (  ListLen(result['errors']) EQ 0  ) { 

					if(	NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
						
						result['error'] 	= true;
						result['errors'] 	= listAppend(result['errors'], "authorize");
						result['message']   = "authorize: User is unauthorized.";
						result['errorsforlog'] = listAppend(result['errorsforlog'], "authorize: User is unauthorized");						
						return representationOf(result).withStatus(401);

					}
	  						  			
	  			} // end: user logged in?				
	  
				// START: valid input?
				if ( ListLen(result['errors']) GT 0 ) { 
					result['error'] = true; 
					
					// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1
					local.logAction = logAction( actionID = 312, extra = result['errorsforlog'] );
					result['message']  = "Oops... seems your submitted input data were not valid.";
					return representationOf(result).withStatus(406);

				} else {
					
					// comment from roberto: the endpoint logic need changing - it needs to take the userID, entityID, entityTypeID and commentText and
					// use the userID to insert the additional details like authorName, authorEmail, etc.. which are mostly used to save joins in the queries
					// to load comments
						
					local.attributes.entityID 	   		= arguments.entityID;
					local.attributes.entityTypeID  		= arguments.entityTypeID;
					local.attributes.userID  			= arguments.userID;
					local.attributes.commentText   	    = arguments.commentText; 
					local.attributes.auth_token 		= arguments.auth_token;
					
					local.comment = httpRequest( methodName = 'POST', endPointOfURL = '/comments/', timeout = 3000, parameters = local.attributes );
					
					// START: success?
					if ( local.comment.status_code NEQ '200' ) {

						result.message  = "Oops... something went wrong while adding the comment.";
						result.status  = false;
						// message: 1111 - 'Comment error' - 'There was an error and your comment was not added. Please try again.'
						// result.message = 1111; 
						local.logAction = logAction( actionID = 1111, extra = "There was an error and your comment was not added. Please try again." );
						
						return representationOf(result).withStatus(500);						 
					
					} else {

						local.data = deserializeJson(local.comment.filecontent);
						
						local.comment = local.data.dataset;
						
						// add [...] if excerpt longer than 255
						if ( len(arguments.commentText) GTE 250 ) {
							local.excerpt = left(arguments.commentText, 250) & "[...]";
						} else {
							local.excerpt = arguments.commentText;	
						}
						
						// comment from roberto: 
						// the logic from line 367 to 432 is used to insert a user friendly activity log
						// make sure each piece of the logic is linking to the entity correctly, like the slug, url, etc.
						
						local.user = httpRequest( methodName = 'GET', endPointOfURL = '/user/#arguments.userID#', timeout = 3000 );
						
						local.data = deserializeJson(local.user.filecontent);

						local.user = local.data.dataset;

						// define activity vars - depending on comment type
						if ( arguments.entityTypeID == 1 ) { 		 // 1, Article Comment, Comment left on an article, 1
							
							local.getDetails = httpRequest( methodName = 'GET', endPointOfURL = '/item/#arguments.entityID#', timeout = 3000 );

							local.data = deserializeJson(local.getDetails.filecontent);

							local.getItem = local.data.dataset;
															
							if ( local.getDetails.status_code EQ '200' ) {

								local.action = "commented-on-item";
								local.content = "<a href='#variables.url#/members/#local.user[1].username#'>#local.user[1].username#</a> posted a <a href='#variables.url#/#local.getItem[1].itemTypeName#/#local.getItem[1].itemSlug##chr(35)#comment-#local.comment[1].commentID#'>comment</a> on the article: <a href='#variables.url#/#local.getItem[1].itemTypeName#/#local.getItem[1].itemSlug#'>#local.getItem[1].itemTitle#</a>.";
								local.primary_link = "#variables.url#/#local.getItem[1].itemTypeName#/#local.getItem[1].itemSlug##chr(35)#comment-#local.comment[1].commentID#";
							
							}	
							
						} else if ( arguments.entityTypeID == 2 ) { // 2, Image Comment, Comment left on an image, 1
							local.action = "commented-on-image";
							local.content = "";
						
						} else if ( arguments.entityTypeID == 3 ) { // 3, Blog Comment, Comment left on a blog, 1																
							
							local.getDetails = httpRequest(methodName = 'GET', endPointOfURL = '/blog/#arguments.entityID#', timeout = 3000 );
							
							local.data = deserializeJson(local.getDetails.filecontent);

							local.getBlog = local.data.dataset;

							if ( local.getDetails.status_code EQ '200' ) {

								local.action = "commented-on-blog";
								local.content = "<a href='#variables.url#/members/#local.user[1].username#'>#local.user[1].username#</a> left a <a href='#variables.url#/blogs/#local.getBlog[1].blogSlug##chr(35)#comment-#local.comment[1].commentID#'>comment</a> on the blog: <a href='#variables.url#/blogs/#local.getBlog[1].blogSlug#'>#local.getBlog[1].blogTitle#</a>.";
								local.primary_link = "#variables.url#/blogs/#local.getBlog[1].blogSlug##chr(35)#comment-#local.comment[1].commentID#";
							
							}								
							
						
						} else if ( arguments.entityTypeID == 4 ) { // 4, Member Comment, Commet on a member profile, 1
							
							local.getDetails = httpRequest(methodName = 'GET', endPointOfURL = '/user/#arguments.entityID#', timeout = 3000 );
							
							local.data = deserializeJson(local.getDetails.filecontent);

							local.getUser = local.data.dataset;

							if ( local.getDetails.status_code EQ '200' ) {

								local.action = "commented-on-member";
								local.content = "<a href='#variables.url#/members/#local.user[1].username#'>#local.user[1].username#</a> posted a <a href='#variables.url#/members/#local.getUser[1].username#/profile/#chr(35)#comment-#local.comment[1].commentID#'>comment</a> on <a href='#variables.url#/members/#local.getUser[1].userName#/profile/'>#local.getUser[1].userName#</a> user profile:";
								local.primary_link = "#variables.url#/members/#local.getUser[1].username#/profile/#chr(35)#comment-#local.comment[1].commentID#";
							
							}
							
						} 
						
						else if ( arguments.entityTypeID == 10 ) { 		 // 5, recipe Comment, Comment left on a recipe, 1
							
							local.getDetails = httpRequest( methodName = 'GET', endPointOfURL = '/recipe/#arguments.entityID#', timeout = 3000 );

							local.data = deserializeJson(local.getDetails.filecontent);

							local.getRecipe = local.data.dataset;
							
							if ( local.getDetails.status_code EQ '200' ) {

								local.action = "commented-on-a-recipe";
								local.content = "<a href='#variables.url#/members/#local.user[1].username#'>#local.user[1].username#</a> submitted an <a href='#variables.url#/recipes/#local.getRecipe[1].slug##chr(35)#comment-#local.comment[1].commentID#'>entry</a> on the recpe: <a href='#variables.url#/recipe/#local.getRecipe[1].slug#'>#local.getRecipe[1].title#</a>.";
								local.primary_link = "#variables.url#/recipes/#local.getRecipe[1].slug##chr(35)#comment-#local.comment[1].commentID#";
							
							}
								
						}
												
						// invoke method: logActivity
						local.logActivity = logActivity( 
							
								userID 		 = arguments.userID,
								component 	 = "updates",
								action 		 = local.action,
								content 	 = local.content,	
								excerpt 	 = local.excerpt,	 
								primary_link = local.primary_link,
								typeID 		 = arguments.entityTypeID, 
								groupID		 = 0,
								objectID 	 = arguments.entityID,
								s_objectID	 = local.comment[1].commentID,
								isVisibleSiteWide = 1
						
						);
	  					
	  							 					
	 					if ( local.comment[1].commentStatusID EQ 1 ) { 
							// message: 1110 - 'Comment in moderation' - 'Your comment was added and is awaiting moderation. Thanks!'
							result.message = 'Your comment was added and is awaiting moderation. Thanks!'; 
							
						} else {
							// message: 1112 - 'Comment published' - 'Your comment was added. Thanks!'
							result.message = 'Your comment was added. Thanks!'; 
							
						}

						result.status  = true;
						return representationOf(result).withStatus(200);
	  
	 				}
					// END: success?

				}
				// END: valid input?

				</cfscript>
					
			</cfcase>
			<!--- METHOD END:: doComment --->

			<!--- METHOD START:: doSignUpFacebook --->
			<cfcase value="doSignUpFacebook">
				
				<cfscript>

				  	arrayOfRequiredArguments = listToArray("email,facebookUserID,access_token,roleID");

				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}

					// verify if provided email is valid
					if ( structKeyExists(arguments, "email") AND NOT isValid("email", arguments.email) ) {
						result['errors'] = listAppend(result['errors'], "email");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "email: #arguments.email#");
					}

					param name="arguments.first_name" 			type="string"  default="";
		  			param name="arguments.last_name" 			type="string"  default="";
		  			param name="arguments.gender" 				type="string"  default="";
		  			param name="arguments.link" 				type="string"  default="";
		  			param name="arguments.locale" 				type="string"  default="";
		  			param name="arguments.timezone" 			type="string"  default="";
		  			param name="arguments.updated_time" 		type="string"  default="";
		  			param name="arguments.verified" 			type="string"  default="";
		  			param name="arguments.profile_image_url" 	type="string"  default="";
		  			param name="arguments.expiry_time" 			type="string"  default="";
		  			param name="arguments.connectedStatus" 		type="numeric" default="1";

					if ( ListLen(result['errors']) GT 0 ) { 

						result['error'] = true;

						// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1
						local.logAction = logAction( actionID = 312, extra = result['errorsforlog'], cgi = arguments.cgi );
						
						return representationOf(result).withStatus(401);

					} else {

						local.attributes = {};
						local.attributes.facebookUserID = arguments.facebookUserID;
						
						existingUserDetails = httpRequest( methodName = 'GET', endPointOfURL = '/facebook', timeout = 3000, parameters = local.attributes );

						facebookUserDetail = deserializeJSON( existingUserDetails.fileContent );

						if( existingUserDetails.status_code EQ 200 AND arrayLen(facebookUserDetail.dataset) ) {

							result['message'] = application.messages['controller_post_dosignupfacebook_accountexist'];

							structAppend(result, facebookUserDetail);

							return representationOf(result).withStatus(200);

						} else {

							FBUserIsExist = application.accountObj.socialFBUserIsExist( facebookUserID = arguments.facebookUserID );

							if( FBUserIsExist.recordCount EQ 0 ) {

								structClear(local.attributes);

		                		local.attributes.facebookUserID 		= arguments.facebookUserID;
		                		local.attributes.email 					= arguments.email;
		                		local.attributes.first_name 			= arguments.first_name;
								local.attributes.last_name				= arguments.last_name;
								local.attributes.gender 				= arguments.gender;
								local.attributes.link 					= arguments.link;
								local.attributes.locale 				= arguments.locale;
								local.attributes.timezone 				= arguments.timezone;
								local.attributes.updated_time 			= arguments.updated_time;
								local.attributes.verified 				= arguments.verified;
								local.attributes.access_token 			= arguments.access_token;
								local.attributes.profile_image_url 		= arguments.profile_image_url;
								local.attributes.expiry_time 			= arguments.expiry_time;
								local.attributes.connectedStatus 		= arguments.connectedStatus;

								//create a new FB user.
		                		createFBUser = httpRequest( methodName = "POST", endPointOfURL = '/facebook', timeout = 3000, parameters = local.attributes );

		                		userDetailsFB = deserializeJSON(createFBUser.fileContent);		                		

		                		result['facebookuserid'] = userDetailsFB.dataset[1].facebookUserID;

		                		result['existfacebookuser'] = false;

							} else {
								
								result['facebookuserid'] = FBUserIsExist.facebookUserID;

								result['existfacebookuser'] = true;
							}

							structClear(local.attributes);

	                 		local.attributes.filters.SearchUserEmail = arguments.email;

	                 		// check providing emailID has already account in users table using GET method of users API endpoint.
	                		userIsExist = httpRequest( methodName = "GET", endPointOfURL = "/users", timeout = 3000, parameters = local.attributes );

	                		// If user doesn't exist, just insert that new user.
	                		if( userIsExist.status_code EQ 404 ) {

	                			if ( structKeyExists(arguments, "profile_image_url") AND trim(arguments.profile_image_url) NEQ "" ) {

	                				// Using URL to store the thumbnail profile picture of the user who is login via facebook
						    		imageFilePath = expandPath('../images/users');
						    		imageID = createUUID();

							    	// Checking whether directory exist or not
							    	if( NOT directoryExists(imageFilePath) ) {
							    		directorycreate(imageFilePath);
							    	}

							    	// Using URL to download that image and store it on local.
							    	downloadAndUploadFile( fileURL = arguments.profile_image_url, filePath = imageFilePath, fileName = "user_" & #imageID# & '.jpg' );
							    	
							    	//create a new user with profile_picture who logined via facebook
							    	createUser = application.accountObj.insertUser( userEmail = arguments.email, userFirstName = arguments.first_name, userLastName = arguments.last_name, userAvatarURL = "/images/users/" & "user_" & imageID, roleID = arguments.roleID );
	                				
	                			} else {

	                				//create a new user who logined via facebook
	                				createUser = application.accountObj.insertUser( userEmail = arguments.email, userFirstName = arguments.first_name, userLastName = arguments.last_name, roleID = arguments.roleID );
	                			}

	                			// Insert User Preferences
								result.insertPreferences = application.accountObj.insertPreferences( userID = createUser.userid );

								// Insert User META
								result.insertUserMeta = application.accountObj.insertUserMeta( userID = createUser.userid );

	                			result['userid'] = createUser.userid;
	                			result['message'] = application.messages['controller_post_dosignupfacebook_success'];
	                			result['existlocaluser'] = false;

	                		} else if( userIsExist.status_code EQ 200 ) {

	                			userDetail = deserializeJSON(userIsExist.fileContent);

	                			result['userid'] = userDetail.dataset[1].userid;
	                			result['message'] = application.messages['controller_post_dosignupfacebook_emailexist'];
	                			result['existlocaluser'] = true;
	                		}
	                		
	                		socialLoginUserIsExist = application.accountObj.getSocialLoginUserDetails( userID = result['userid'], socialLoginTypeID = 4, socialLoginUserID = result['facebookuserid'] );

                			if( socialLoginUserIsExist.recordCount EQ 0 ) {
                				//insert login details via facebook.
                				application.accountObj.insertSocialUserLogin( userID = result['userid'], socialLoginTypeID = 4, socialLoginUserID = result['facebookuserid'], isMainAccount = 1 );
                			}
	                		
	                 		structClear(local.attributes);
	                 		local.attributes.facebookUserID = result['facebookuserid'];

	                 		//using GET function of socialFacebook API endpoint to get details of new user's details for displaying, it returns auth_token too
	                		getUserDetails = httpRequest( methodName = "GET", endPointOfURL = "/facebook", timeout = 3000, parameters = local.attributes );

	                		getUserDetails = deserializeJSON(getUserDetails.fileContent);

	                		structAppend(result, getUserDetails);
	                		
	                		return representationOf(result).withStatus(200);
						}
					}

				</cfscript>

			</cfcase>
			<!--- METHOD END:: doSignUpFacebook --->

			<!--- METHOD START:: doSignUpTwitter --->
			<cfcase value="doSignUpTwitter">
				
				<cfscript>

					arrayOfRequiredArguments = listToArray("email,twitterUserID,name,screen_name,access_token_secret,roleID");

					for( element in arrayOfRequiredArguments ) {
						if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len( trim(arguments[element]))) ) {
							result['errors'] = listAppend( result['errors'], element );
							result['errorsforlog'] = listAppend( result['errorsforlog'], element & " is required" );
						}
					}

					// verify if provided email is valid
					if ( structKeyExists(arguments, "email") AND NOT isValid("email", arguments.email) ) {
						result['errors'] = listAppend(result['errors'], "email");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "Invalid email: " & arguments.email);
					}
					
					param name="arguments.location" 			type="string" 	default="";
		  			param name="arguments.profile_location" 	type="string" 	default="";
		  			param name="arguments.description" 			type="string" 	default="";
		  			param name="arguments.url" 					type="string" 	default="";
		  			param name="arguments.followers_count" 		type="numeric" 	default="0";
		  			param name="arguments.friends_count" 		type="numeric" 	default="0";
		  			param name="arguments.listed_count" 		type="numeric" 	default="0";
		  			param name="arguments.favourites_count" 	type="numeric" 	default="0";
		  			param name="arguments.statuses_count" 		type="numeric" 	default="0";
		  			param name="arguments.created_at" 			type="string" 	default="";
		  			param name="arguments.utc_offset" 			type="string" 	default="";
		  			param name="arguments.time_zone" 			type="string" 	default="";
		  			param name="arguments.profile_image_url" 	type="string" 	default="";
		  			param name="arguments.access_token" 		type="string" 	default="";
		  			param name="arguments.connectedStatus" 		type="numeric" 	default="1";

					if ( ListLen(result['errors']) GT 0 ) { 

						result['error'] = true;
						// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1
						local.logAction = logAction( actionID = 312, extra = result['errorsforlog'], cgi = arguments.cgi );
						
						return representationOf(result).withStatus(401);

					} else {

						local.attributes = {};
	                 	local.attributes.twitterUserID = arguments.twitterUserID;

						existingUserDetails = httpRequest( methodName = "GET", endPointOfURL = "/twitter", timeout = 3000, parameters = local.attributes );

						twitterUserDetail = deserializeJSON(existingUserDetails.filecontent);

						if( existingUserDetails.status_code EQ 200 AND arrayLen(twitterUserDetail.dataset) ) {
							
							result['message'] = application.messages['controller_post_dosignuptwitter_accountexist'];

							structAppend(result, twitterUserDetail);

							return representationOf(result).withStatus(200);

						} else {
							
							twitterUserIsExist = application.accountObj.socialTwitterUserIsExist( twitterUserID = arguments.twitterUserID );

	                		if ( twitterUserIsExist.recordCount EQ 0 ) {

	                			structClear(local.attributes);

		                		local.attributes.twitterUserID 			= arguments.twitterUserID;
		                		local.attributes.name 	 				= arguments.name;
		                		local.attributes.screen_name 			= arguments.screen_name;
								local.attributes.location				= arguments.location;
								local.attributes.profile_location 		= arguments.profile_location;
								local.attributes.description 			= arguments.description;
								local.attributes.url 					= arguments.url;
								local.attributes.followers_count 		= arguments.followers_count;
								local.attributes.friends_count 			= arguments.friends_count;
								local.attributes.listed_count 			= arguments.listed_count;
								local.attributes.favourites_count 		= arguments.favourites_count;
								local.attributes.statuses_count 		= arguments.statuses_count;
								local.attributes.created_at 			= arguments.created_at;
								local.attributes.utc_offset 			= arguments.utc_offset;
								local.attributes.time_zone 				= arguments.time_zone;
								local.attributes.profile_image_url 		= arguments.profile_image_url;
								local.attributes.access_token 			= arguments.access_token;
								local.attributes.access_token_secret 	= arguments.access_token_secret;
								local.attributes.connectedStatus 		= arguments.connectedStatus;

								//create a new FB user using POST function of twitter API endpoint.
		                		createTwitterUser = httpRequest( methodName = "POST", endPointOfURL = '/twitter', timeout = 3000, parameters = local.attributes );

		                		userDetailsTW = deserializeJSON(createTwitterUser.filecontent);

		                		result['twitteruserid'] = userDetailsTW.dataset[1].twitterUserID;
		                		result['existtwitteruser'] = false;

	                		} else {

	                			result['twitteruserid'] = twitterUserIsExist.twitterUserID;
	                			result['existtwitteruser'] = true;
	                		}

							structClear(local.attributes);

	                 		local.attributes.filters.SearchUserEmail = arguments.email;

	                 		// Find Twitter user already existed in our APP or not using GET method of users API endpoint.
	                		userIsExist = httpRequest( methodName = "GET", endPointOfURL = "/users", timeout = 3000, parameters = local.attributes );

	                		if( userIsExist.status_code EQ 404 ) {						

	                			if ( structKeyExists(arguments, "profile_image_url") AND trim(arguments.profile_image_url) NEQ "" ) {

	                				// Using URL to store the thumbnail profile picture of the user who is login via twitter
						    		imageFilePath = expandPath('../images/users');
						    		imageID = createUUID();

							    	// Checking whether directory exist or not
							    	if( NOT directoryExists(imageFilePath) ) {
							    		directorycreate(imageFilePath);
							    	}

							    	// Using URL to download that image and store it on local.
							    	downloadAndUploadFile( fileURL = arguments.profile_image_url, filePath = imageFilePath, fileName = "user_" & #imageID# & '.jpg' );
							    	
							    	//create a new user with profile_picture who logined via twitter
	                				createUser = application.accountObj.insertUser( userName = arguments.screen_name, userEmail = arguments.email, userAvatarURL = "/images/users/" & "user_" & imageID, roleID = arguments.roleID );

	                			} else {

	                				//create a new user without profile_picture who logined via twitter
	                				createUser = application.accountObj.insertUser( userName = arguments.screen_name, userEmail = arguments.email, roleID = arguments.roleID );
	                			}

	                			// Insert User Preferences
								result.insertPreferences = application.accountObj.insertPreferences( userID = createUser.userid );

								// Insert User META
								result.insertUserMeta = application.accountObj.insertUserMeta( userID = createUser.userid );							

	                			result['userid'] = createUser.userid;
	                			result['message'] = application.messages['controller_post_dosignuptwitter_success'];
	                			result['existlocaluser'] = false;

	                		} else if( userIsExist.status_code EQ 200 ) {

	                			userDetail = deserializeJSON(userIsExist.filecontent);

	                			result['userid'] = userDetail.dataset[1].userid;
	                			result['message'] = application.messages['controller_post_dosignuptwitter_exist'];
	                			result['existlocaluser'] = true;
	                		} 

	                		socialLoginUserIsExist = application.accountObj.getSocialLoginUserDetails( userID = result['userid'], socialLoginTypeID = 13, socialLoginUserID = result['twitteruserid'] );

	                		if( socialLoginUserIsExist.recordCount EQ 0 ) {
	                			//insert login details via facebook.
	                			application.accountObj.insertSocialUserLogin( userID = result['userid'], socialLoginTypeID = 13, socialLoginUserID = result['twitteruserid'], isMainAccount = 1 );
	                		}

	                		structClear(local.attributes);
	                 		local.attributes.twitterUserID = result['twitteruserid'];

	                 		//using GET function of socialTwitter API endpoint to get details of new user'details for displaying, it returns auth_token too
	                		getUserDetails = httpRequest( methodName = "GET", endPointOfURL = "/twitter", timeout = 3000, parameters = local.attributes );

	                		getUserDetails = deserializeJSON(getUserDetails.filecontent);

	                		structAppend(result, getUserDetails);

	                		return representationOf(result).withStatus(200);
						}
					}

				</cfscript>

			</cfcase>
			<!--- METHOD END:: doSignUpTwitter --->

			<!--- METHOD START:: doSignUpInstagram --->
			<cfcase value="doSignUpInstagram">
				
				<cfscript>
					
					arrayOfRequiredArguments = listToArray('email,instagramUserID,username,access_token,roleID');
					
					// verify the arguments exist or not
					for(element in arrayOfRequiredArguments) {

						if(NOT structKeyExists(arguments,element) OR (structKeyExists(arguments,element) AND NOT len(trim(arguments[element]))) ) {
							
							result['errors'] = listAppend(result['errors'], element);
							result['errorsforlog'] = listAppend(result['errorsforlog'], element & ' is required');
						}


					}

					if( isDefined("arguments.email") AND NOT isvalid('email', arguments.email) ){
						result['errors'] = listAppend(result['errors'], email);
						result['errorsforlog'] = listAppend(result['errorsforlog'], 'Invalid email: ' & arguments.email);
					}

					param name="arguments.bio"			 		type="string"	 default="";
					param name="arguments.website" 		 		type="string"	 default="";
					param name="arguments.profile_picture" 		type="string"	 default="";
					param name="arguments.full_name" 		 	type="string"	 default="";
					param name="arguments.count_media" 			type="numeric"	 default="0";
					param name="arguments.count_followed_by" 	type="numeric"	 default="0";
					param name="arguments.count_follows" 		type="numeric" 	 default="0";
					param name="arguments.access_token" 		type="string"  	 default="";
					param name="arguments.connectedStatus" 		type="numeric" 	 default="1";

					if( ListLen(result['errors']) GT 0  ) {
						result['error'] = true;
						
						// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1
						local.logAction = logAction( actionID = 312, extra = result['errorsforlog'], cgi = arguments.cgi );
						
						return representationOf(result).withStatus(401);
					} else {

						local.attributes 	= {};
						local.attributes.instagramUserID = arguments.instagramUserID;
						
						existingUserDetails = httpRequest( methodName ='GET', endPointOfURL='/instagram', timeout = 3000, parameters = local.attributes);
						
						instagramUserDetail = deserializeJSON(existingUserDetails.filecontent);

						if(existingUserDetails.status_code EQ 200 AND arrayLen(instagramUserDetail.dataset)) {

							result['message'] = application.messages['controller_post_dosignupinstagram_accountexist'];
							structAppend(result,instagramUserDetail);
							return representationOf(result).withStatus(200);
							
						} else {

							instagramUserIsExist = application.accountObj.socialUserInstagramExist( instagramUserID= arguments.instagramUserID );

							if( instagramUserIsExist.recordCount EQ 0 ){

								structClear(local.attributes);

								local.attributes.instagramUserID 	 = arguments.instagramUserID;
								local.attributes.username 			 = arguments.username;
								local.attributes.bio 				 = arguments.bio;
								local.attributes.website 			 = arguments.website;
								local.attributes.profile_picture 	 = arguments.profile_picture;
								local.attributes.full_name 			 = arguments.full_name;
								local.attributes.count_media 		 = arguments.count_media;
								local.attributes.count_follows 		 = arguments.count_follows;
								local.attributes.count_followed_by 	 = arguments.count_followed_by;
								local.attributes.access_token 		 = arguments.access_token;
								local.attributes.connectedStatus 	 = arguments.connectedStatus;
								
								// a new instagram user using POST function of instagram API endpoint.
								createInstagramUser 		 = httpRequest(methodName = "POST", endPointOfURL = "/instagram", timeout = 3000, parameters = local.attributes);
								userDetailsInstagram		 = deserializeJSON(createInstagramUser.fileContent);
								
								result['instagramuserid'] 	 = userDetailsInstagram.dataset[1].instagramUserID;
		                		result['existinstagramuser'] = false;

		                	} else {

	                			result['instagramuserid'] 	 = instagramUserIsExist.instagramUserID;
	                			result['existinstagramuser'] = true;

		                 	}

	                 		structClear(local.attributes);
	                 		local.attributes.filters.SearchUserEmail = arguments.email;

	                 		// Find Instagram user already existed in our APP or not using GET method of users API endpoint.
							userIsExist = httpRequest( methodName = "GET", timeout= 3000, endPointOfURL = "/users", parameters = local.attributes );

							if( userIsExist.status_code EQ 404 ) {

								if ( structKeyExists(arguments, "profile_image") AND trim(arguments.profile_image) NEQ "" ) {

	                				// Using URL to store the thumbnail profile picture of the user who is login via instagram
						    		imageFilePath = expandPath('../images/users');
						    		imageID = createUUID();
							    	
							    	// Checking whether directory exist or not
							    	if( NOT directoryExists(imageFilePath) ) {
							    		directorycreate(imageFilePath);
							    	}

							    	// Using URL to download that image and store it on local.
							    	downloadAndUploadFile( fileURL = arguments.profile_image, filePath = imageFilePath, fileName = "user_" & #imageID# & '.jpg' );
							    	
							    	//create a new user with profile_picture who logined via instagram
	                				createUser = application.accountObj.insertUser( userName = arguments.username, userEmail = arguments.email, userAvatarURL = "/images/users/" & "user_" & imageID, roleID = arguments.roleID );

		                		} else {

									// create a user without profile_picture who logged in via instagram
									createUser 	= application.accountObj.insertUser( userName = arguments.username, userEmail = arguments.email, roleID = arguments.roleID );

								}

								// Insert User Preferences
								result.insertPreferences = application.accountObj.insertPreferences( userID = createUser.userid );

								// Insert User META
								result.insertUserMeta = application.accountObj.insertUserMeta( userID = createUser.userid );

								result['userID'] 		 = createUser.userid;
								result['message'] 		 = application.messages['controller_post_dosignupinstagram_success'];
								result['existlocaluser'] = false;

							} else if ( userIsExist.status_code EQ 200 ) {

								userDetail 				 = deserializeJSON(userIsExist.filecontent);
								result['userid']   		 = userdetail.dataset[1].userid;
								result['message']   	 = application.messages['controller_post_dosignupinstagram_exist'];
								result['existlocaluser'] = true;
							}
						
							socialLoginUserIsExist = application.accountObj.getSocialLoginUserDetails( userID = result['userid'], socialLoginTypeID = 16, socialLoginUserID = result['instagramuserid'] );               		

							if( socialLoginUserIsExist.recordCount EQ 0 ) {
	                			//insert login details via instagram.
	                			application.accountObj.insertSocialUserLogin( userID = result['userid'], socialLoginTypeID = 16, socialLoginUserID = result['instagramuserid'], isMainAccount = 1 );
                			}

                			structClear(local.attributes);
                 			local.attributes.instagramUserID = result['instagramuserid'];

                 			//using GET function of socialInstagram API endpoint to get details of new user'details for displaying, it returns auth_token too

                 			getUserDetails = httpRequest( methodName = 'GET', endPointOfURL = '/instagram', timeout = 3000, parameters = local.attributes);

                 			getUserDetails = deserializeJSON(getUserDetails.fileContent);
                 			
                 			structAppend(result, getUserDetails);

							return representationOf(result).withStatus(200);

						}

					}
				</cfscript>

			</cfcase>
			<!--- METHOD END:: doSignUpInstagram --->
			
			<!--- METHOD START:: doUpdatePassword --->
			<cfcase value="doUpdatePassword">
				
				<cfscript>

		  				arrayOfRequiredArguments = listToArray("auth_token,userID,isUpdatePassword,userPasswordNew,userPasswordConfirm");
	
					  	for( element in arrayOfRequiredArguments ) {
					  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
					  			result['errors'] = listAppend(result['errors'], element);
					  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
					  		}
					  	}

					  	if ( ListLen(result['errors']) EQ 0 ) {

					  		if ( arguments.isUpdatePassword EQ 1 AND NOT structKeyExists(arguments, 'userPassword') ) {
								result['errors'] = listAppend(result['errors'], "userPassword");
								result['errorsforlog'] = listAppend(result['errorsforlog'], "userPassword is required");
							}

					  	}

					  	if ( ListLen(result['errors']) EQ 0 ) {

					  		if ( len(arguments.userPasswordNew) LT 6 ) {
								result['errors'] = listAppend(result['errors'], "userPasswordNew");
								result['errorsforlog'] = listAppend(result['errorsforlog'], "userPasswordNew not long enough");
							}	
				
							// check password match passwordConfirm
							if ( trim(arguments.userPasswordNew) NEQ trim(arguments.userPasswordConfirm) ) {
								result['errors'] = listAppend(result['errors'], "userPasswordConfirm");
								result['errorsforlog'] = listAppend(result['errorsforlog'], "userPasswordConfirm: #arguments.userPasswordConfirm#");
							}

						}
	
						if ( ListLen(result['errors']) GT 0 ) {  // start: errors in parameters?
	
							result['error'] = true;
							
							// Log - Password: Invalid Input - User entered invalid input while updating password.
							local.logAction = logAction( actionID = 243, extra = result['errorsforlog'], cgi = arguments.cgi );
							
							return representationOf(result).withStatus(406);
	
						} else {

							// start: user logged in?		  			
							local.attributes.auth_token = arguments.auth_token;
			  				local.attributes.userID 	= arguments.userID;

			  				local.authorize = httpRequest(methodName = 'GET', endPointOfURL = '/authorize/', timeout = 3000, parameters = local.attributes );

			  				local.authorized = deserializeJson(local.authorize.filecontent);
			  				
							if(	local.authorize.status_code NEQ 200 ) {
								
								result['errors'] = listAppend(result['errors'], "authorize");
								result['errorsforlog'] = listAppend(result['errorsforlog'], "authorize: User is unauthorized");
								
								return representationOf(result).withStatus(401);

							}
							// end: user logged in?
							if( arguments.isUpdatePassword EQ 1 ){
								checkPassword = application.accountObj.checkPassword( userID = arguments.userID, userPassword = arguments.userPassword );
                			}
                			// start: valid password?
                			if( arguments.isUpdatePassword EQ 1 AND checkPassword.recordCount EQ 0  ) {
	                			
                				// Log - Password: Invalid Input - User entered invalid input while updating password.
								local.logAction = logAction( actionID = 243, extra = result['errorsforlog'], cgi = arguments.cgi );
								
								return representationOf(result).withStatus(401);
								
							} else {
								
								local.attributes = {};								
								local.attributes.userPassword = arguments.userPasswordNew;
								
								// using PUT function of user API endpoint to update the password
								updateUserPassword = httpRequest( methodName = "PUT", endPointOfURL = "/user/#arguments.userID#", timeout = 3000, parameters = local.attributes );
								
	                			result['message'] = application.messages['controller_post_doUpdatePassword_success'];	                			
								
								return representationOf(result).withStatus(200);
								
                			} // end: valid password?
	                		
						} // end: errors in parameters?

				</cfscript>

			</cfcase>
			<!--- METHOD END:: doUpdatePassword --->
			
			<!--- METHOD START:: doUpdatePublisherSettings --->
			<cfcase value="doUpdatePublisherSettings">
		
				<cfscript>

					local.attributes = structNew();
					
					param name="arguments.userAddressLine2" type="string"  default="";
					param name="arguments.userPhone" 		type="string"  default="0";
					param name="arguments.userPhone1Ext" 	type="string"  default="";
					param name="arguments.userStateID" 		type="numeric" default="0";					
					param name="arguments.userZip"			type="string"  default="";
					param name="arguments.company_typeID" 	type="string"  default="";
					param name="arguments.tax_ID" 			type="string"  default="";
		
					arrayOfRequiredArguments = listToArray("auth_token,userID,payment_email,UserEmail,userFirstName,userLastName,userAddressLine1,userCity,userCountryID");
	
				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}
				  	
				  	// start: missing parameters?
				  	if ( ListLen(result['errors']) GT 0 ) {
					  	
					  	// Log - Profile: Invalid Input - User entered invalid profile input
						local.logAction = logAction( actionID = 231, extra = result['errorsforlog'], cgi = arguments.cgi );
					  	return representationOf(result).withStatus(406);

					} else {
										  	
		  				// start: authorized?		  				
						if ( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
							
							result['errors'] = listAppend(result['errors'], "authorize");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "authorize: User is unauthorized");

							// Log - Authorized: Invalid Authorized - User entered invalid profile input
							local.logAction = logAction( actionID = 231, extra = result['errorsforlog'], cgi = arguments.cgi );
														
							return representationOf(result).withStatus(401);
	
						} // end: authorized
					
					} // end: missing parameters?
		
		 			// start: user is authenticated and all parameters are present. now validate!
		 			if ( ListLen(result.errors) EQ 0 ) { 
		  	
						// verify if provided email is valid
						if ( NOT isValid("email", arguments.payment_email) ) {
							result['errors'] = listAppend(result['errors'], "payment_email");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "payment_email: #arguments.payment_email#");
						}	
	
						// verify if provided email is valid
						if ( NOT isValid("email", arguments.UserEmail) ) {
							result['errors'] = listAppend(result['errors'], "UserEmail");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "UserEmail: #arguments.UserEmail#");
						}
	
						// verify firstName
						if ( len(TRIM(arguments.userFirstName)) EQ 0 ) {
							result['errors'] = listAppend(result['errors'], "userFirstName");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userFirstName: #arguments.userFirstName#");
						}	
	
						// verify lastName
						if ( len(TRIM(arguments.userLastName)) EQ 0 ) {
							result['errors'] = listAppend(result['errors'], "userLastName");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userLastName: #arguments.userLastName#");
						}
	
						// verify userAddressLine1
						if ( len(TRIM(arguments.userAddressLine1)) EQ 0 ) {
							result['errors'] = listAppend(result['errors'], "userAddressLine1");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userAddressLine1: #arguments.userAddressLine1#");
						}
	
						// verify userCity
						if ( len(TRIM(arguments.userCity)) EQ 0 ) {
							result['errors'] = listAppend(result['errors'], "userCity");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userCity: #arguments.userCity#");
						}				
	
						// verify userZip and UserState is US
						if ( TRIM(arguments.userCountryID) EQ 224 ) {
						
							// verify userZip
							if ( len(TRIM(arguments.userZip)) EQ 0 ) {
								result['errors'] = listAppend(result['errors'], "userZip");
								result['errorsforlog'] = listAppend(result['errorsforlog'], "userZip: #arguments.userZip#");
							}	
				
							// verify userStateID
							if ( TRIM(arguments.userStateID) EQ 0 ) {
								result['errors'] = listAppend(result['errors'], "userStateID");
								result['errorsforlog'] = listAppend(result['errorsforlog'], "userStateID: #arguments.userStateID#");
							}
	
							// verify company_typeID
							if ( len(TRIM(arguments.company_typeID)) EQ 0 ) {
								result['errors'] = listAppend(result['errors'], "company_typeID");
								result['errorsforlog'] = listAppend(result['errorsforlog'], "company_typeID: #arguments.company_typeID#");
							}	
					
							// verify tax_ID
							if ( len(TRIM(arguments.tax_ID)) EQ 0 ) {
								result['errors'] = listAppend(result['errors'], "tax_ID");
								result['errorsforlog'] = listAppend(result['errorsforlog'], "tax_ID: #arguments.tax_ID#");
							}						
						
						}
			
						// verify userCountryID
						if ( TRIM(arguments.userCountryID) EQ 0 OR NOT isNumeric(arguments.userCountryID)) {
							result['errors'] = listAppend(result['errors'], "userCountryID");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userCountryID: #arguments.userCountryID#");
						}					
					
					} // end: user is authenticated and all parameters are present. now validate!
					
			 		// START: any errors?
					if ( ListLen(result.errors) GT 0 ) { 
						result.error = true; 
							
						// Log - Profile: Invalid Input - User entered invalid profile input
						local.logAction = logAction( actionID = 231, extra = result['errorsforlog'], cgi = arguments.cgi );
						
						return representationOf(result).withStatus(406); 
						
					} else { // no errors.. update everything
						
						// updateUserProfile record	
						structClear(local.attributes);

						local.attributes.UserEmail 			= arguments.UserEmail;
						local.attributes.userFirstName 		= arguments.userFirstName;
						local.attributes.userLastName 		= arguments.userLastName;
						local.attributes.userAddressLine1	= arguments.userAddressLine1;
						local.attributes.userAddressLine2	= arguments.userAddressLine2;
						local.attributes.userCity			= arguments.userCity;
						local.attributes.userStateID		= arguments.userStateID;
						local.attributes.userZip			= arguments.userZip;
						local.attributes.userCountryID		= arguments.userCountryID;
						local.attributes.userPhone			= arguments.userPhone;
						local.attributes.userPhone1Ext		= arguments.userPhone1Ext;
						local.attributes.userID				= arguments.userID;
						local.attributes.active				= 1;
						
						local.updateUserProfile = httpRequest(methodName = "PUT", endPointOfURL = "/user/#arguments.userID#", timeout = 3000, parameters = local.attributes);
						// updatePublisherMeta records

						structClear(local.attributes);
						local.attributes.key 		= "payment_email";
						local.attributes.value 		= arguments.payment_email;
						local.attributes.userID 	= arguments.userID;
						local.attributes.auth_token = arguments.auth_token;
						
						local.updatePublisherMeta = httpRequest(methodName = "PUT", endPointOfURL = "/publishersMeta/", timeout = 3000, parameters = local.attributes);
						
						structClear(local.attributes);
						local.attributes.key 		= "tax_ID";
						local.attributes.value 		= arguments.tax_ID;
						local.attributes.userID 	= arguments.userID;
						local.attributes.auth_token = arguments.auth_token;						

						local.updatePublisherMeta = httpRequest(methodName = "PUT", endPointOfURL = "/publishersMeta/", timeout = 3000, parameters = local.attributes);

						structClear(local.attributes);
						local.attributes.key 		= "company_typeID";
						local.attributes.value 		= arguments.company_typeID;
						local.attributes.userID 	= arguments.userID;
						local.attributes.auth_token = arguments.auth_token;							

						local.updatePublisherMeta = httpRequest(methodName = "PUT", endPointOfURL = "/publishersMeta/", timeout = 3000, parameters = local.attributes);
						
						if ( isDefined("arguments.agreeTerms") ) {

							structClear(local.attributes);
							local.attributes.userID = arguments.userID;
							local.attributes.key 	= "agreeTerms";
							local.attributes.value 	= 1;

							local.updatePublisherMeta = httpRequest(methodName = "PUT", endPointOfURL = "/publishersMeta/", timeout = 3000, parameters = local.attributes);
							
						}

			 			// START: updateUserProfile success? check if the PUT endpoint call to /user returned a 200...
						if ( local.updateUserProfile.status_code NEQ 200 ) {
							
							// result.message = 455;
							result['message'] = application.messages['controller_post_doUpdatePublisherSettings_error'];							
							result['errorsforlog'] = listAppend(result['errorsforlog'], "updateUserProfile: There was some error occur while updating the user details");
							// Log - Profile: Invalid Input - User entered invalid profile input
							local.logAction = logAction( actionID = 615, extra = result['errorsforlog'], cgi = arguments.cgi );
							return representationOf(result).withStatus(500); 
							
						} else {
							
							result['message'] = application.messages['controller_post_doUpdatePublisherSettings_success'];	                			
							local.logAction = logAction( actionID = 505, cgi = arguments.cgi );
							return representationOf(result).withStatus(200);				  					 
								
						} // END: updateUserProfile success?
					
					
					} // END: any errors?
				</cfscript>
						
			</cfcase>
			<!--- METHOD END:: doUpdatePublisherSettings --->
			
			<!--- METHOD START:: doUpdateProfileDetails --->
			<cfcase value="doUpdateProfileDetails">
		  	   
				<!--- // START: form validation --->
				<cfscript>
				
				local.attributes = structNew();

					param name="arguments.userImageID"      type="numeric"  default="0";
					param name="arguments.userAddressLine1" type="string"  default="";
 					param name="arguments.userAddressLine2" type="string"  default="";
					param name="arguments.userAddressLine3" type="string"  default="";
					param name="arguments.userStateID" 		type="numeric" default="0";				
					param name="arguments.userZip"			type="string"  default="";
					param name="arguments.userDateBirth"	type="string"  default="";
					param name="arguments.userGender"       type="string"  default="";
					param name="arguments.userAbout"		type="string"  default="";
					param name="arguments.usercity"         type="string"  default="";
					arrayOfRequiredArguments = listToArray("auth_token,userID,userEmail,userFirstName,userLastName,userCountryID,userGender");
	
				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}
				  	
				  	// start: missing parameters?
				  	if ( ListLen(result['errors']) GT 0 ) {
					  	
					  	// Log - Profile: Invalid Input - User entered invalid profile input
						local.logAction = logAction( actionID = 231, extra = result['errorsforlog'], cgi = arguments.cgi );
					  	return representationOf(result).withStatus(406);

					} else {
										  	
		  				// start: authorized?		  				
						if ( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
							
							result['errors'] = listAppend(result['errors'], "authorize");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "authorize: User is unauthorized");

							// Log - Authorized: Invalid Authorized - User entered invalid profile input
							local.logAction = logAction( actionID = 231, extra = result['errorsforlog'], cgi = arguments.cgi );
							return representationOf(result).withStatus(401);
	
						} // end: authorized
					
					} // end: missing parameters?
		  
		  
					// start: user is authenticated and all parameters are present. now validate!
		 			if ( ListLen(result.errors) EQ 0 ) { 
		  	
						// verify if provided email is valid
						if ( NOT isValid("email", arguments.userEmail) ) {
							result['errors'] = listAppend(result['errors'], "userEmail");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userEmail: #arguments.userEmail#");
						}	
	  			
						// verify first name
						if ( len(TRIM(arguments.userFirstName)) EQ 0 ) {
							result['errors'] = listAppend(result['errors'], "userFirstName");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userFirstName: #arguments.userFirstName#");
						}	
						
						// verify last name
						if ( len(TRIM(arguments.userLastName)) EQ 0 ) {
							result['errors'] = listAppend(result['errors'], "userLastName");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userLastName: #arguments.userLastName#");
						}
						
						// verify country
						if ( NOT isNumeric(arguments.userCountryID) ) {
							result['errors'] = listAppend(result['errors'], "userCountryID");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userCountryID: #arguments.userCountryID#");
						}
							
						// verify gender
						if ( TRIM(arguments.userGender) EQ 0 ) {
							result['errors'] = listAppend(result['errors'], "userGender");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userGender: #arguments.userGender#");
						} 	
		
					} // end: user is authenticated and all parameters are present. now validate!
					
			 		// START: any errors?
					if ( ListLen(result.errors) GT 0 ) { 
						result.error = true; 
							
						// Log - Profile: Invalid Input - User entered invalid profile input
						local.logAction = logAction( actionID = 231, extra = result['errorsforlog'], cgi = arguments.cgi );
						
						return representationOf(result).withStatus(406); 
						
					} else { // no errors.. update everything
						 							
						// updateUserProfile record	
						structClear(local.attributes);
						local.attributes.userImageID 		= arguments.userImageID;
						local.attributes.userEmail 			= arguments.userEmail;
						local.attributes.userFirstName 		= arguments.userFirstName;
						local.attributes.userLastName 		= arguments.userLastName;
						local.attributes.userGender			= arguments.userGender;
						local.attributes.userAddressLine1	= arguments.userAddressLine1;
						local.attributes.userAddressLine2	= arguments.userAddressLine2;
						local.attributes.userAddressLine3	= arguments.userAddressLine3;
						local.attributes.userDateBirth		= arguments.userDateBirth;
						local.attributes.userCity			= arguments.userCity;
						local.attributes.userStateID		= arguments.userStateID;
						local.attributes.userZip			= arguments.userZip;
						local.attributes.userCountryID		= arguments.userCountryID;
						local.attributes.userAbout			= arguments.userAbout;
						local.attributes.userID				= arguments.userID;
						local.attributes.active				= 1;

						local.updateUserProfile = httpRequest(methodName = "PUT", endPointOfURL = "/user/#arguments.userID#", timeout = 3000, parameters = local.attributes);
					
						// START: updateUserProfile success? check if the PUT endpoint call to /user returned a 200...
						if ( local.updateUserProfile.status_code NEQ 200 ) {

							result['message'] = application.messages['controller_post_doUpdateProfileDetails_error'];							
							result['errorsforlog'] = listAppend(result['errorsforlog'], "updateUserProfile: There was some error occur while updating the user details");
							// Log - Profile: Invalid Input - User entered invalid profile input
							local.logAction = logAction( actionID = 615, extra = result['errorsforlog'], cgi = arguments.cgi );
							return representationOf(result).withStatus(500); 

						} else {

							result['message'] = application.messages['controller_post_doUpdateProfileDetails_success'];	                			
							local.logAction = logAction( actionID = 505, cgi = arguments.cgi );	
							return representationOf(result).withStatus(200);				  					 
								
						} // END: updateUserProfile success?
					
					} // END: any errors?
				</cfscript>
	
			</cfcase>
			<!--- METHOD END:: doUpdateProfileDetails --->

			<!--- METHOD START:: doActivateMember --->
			<cfcase value="doActivateMember">	
	
			<!--- // START: form validation --->
				<cfscript>
					local.attributes = structNew();


					// verify if valid UUID
					if ( len(arguments.UUID) NEQ 25 ) {
						// Log: 335, Activate Account: Invalid UUID, The UUID provided is invalid, 1
							// local.tmp = application.dataObj.logAction( actionID = 335, cgi = arguments.cgi );
							result['errors'] = listAppend(result['errors'], "UUID");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "UUID: #arguments.UUID#");
							result.message = 'The given UUID is not valid.'
					}
						
					if ( len(result.errors) GT 0) {
					
						// message: 72, Activate Account: Not Found, The account is either not found or it was previously already verified., 1, 1
							
						return representationOf(result).withStatus(500);		
	 	 		 	
					} else {
						 
							local.attributes.userConfirmationCode = arguments.UUID;			
							local.activateAccount = httpRequest(methodName = 'PUT', endPointOfURL = '/activateAccount/', timeout = 3000, parameters = local.attributes );
		 				// START: activateAccount success?
						if ( local.activateAccount.statuscode EQ '200 ok' ) {
							 local.activateUserID = deserializeJSON(local.activateAccount.filecontent);
 							// email user with account activated confirmation
							if(local.activateUserID.alreadyActivated EQ 0){

								local.email.attributes = "{
														'emailID'  = '638',
														'TOuserID' = '#local.activateUserID.userID#',
														'CCuserID' = '1',
														'userID'   = '1',
														'blogID'   = '0',
														'insertConfirmationCode' = '1'
													    }";

								local.email.notificationName = 'sendEmailToUser';

								local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );
							
								local.sendEmail = deserializeJson(local.sendEmail.filecontent);
						
								result.message  = application.messages['controller_post_doActivateMember_success'];
								result['alreadyExist'] = 0;

							} else {

								result.message  = application.messages['controller_post_doActivateMember_exist'];
								result['alreadyExist'] = 1;

							}
							result.status  = true;

							return representationOf(result).withStatus(200);	
		  				
		 				} else {

		 					result['errors'] = listAppend(result['errors'], "UUID");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "UUID: #arguments.UUID#");
		 					result.message = application.messages['controller_post_doActivateMember_error'];
		 					result.status  = "false";
		 					return representationOf(result).withStatus(404);
		 				}
						// END: activateAccount success?				
	  				
		 		 	}
					// END: verify if valid UUID
					
				</cfscript>
		
			</cfcase>
			<!--- METHOD END:: doActivateMember --->

			<!--- METHOD START:: doResetPassword --->
			<cfcase value="doResetPassword">	
	
				<!--- // START: form validation --->
				<cfscript>
				
					// verify if valid UUID
					if ( len(arguments.UUID) NEQ 35 ) {

						// Log: 321, 'Reset Password: Invalid UUID', 'User submitted invalid input with reset password form', 1
						// local.tmp = application.dataObj.logAction( actionID = 321, extra = local.errorsForLog, cgi = arguments.cgi );
						result['errors'] = listAppend(result['errors'], "UUID");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "UUID: #arguments.UUID#");
						return representationOf(result).withStatus(406);
					} else {
						 
						// generate new password
						local.attributes.newpassword = left(replace(CreateUUID(), "-", ""), 7);
			 			local.attributes.uuid = arguments.uuid;

			 			// call PUT method in /pasword/ endPoint

						local.resetUserPassword = httpRequest( methodName = 'PUT', endPointOfURL = '/password', timeout = 3000, parameters = local.attributes );				

			 			// START: resetUserPassword success?
						if ( local.resetUserPassword.statuscode EQ '200 ok' ) {

							local.resetPasswordUserID = deserializeJSON(local.resetUserPassword.filecontent);

							//Get user details from /user/{id} endpoint
							local.getUserByUserID = httpRequest( methodName = 'GET', endPointOfURL = '/User/#local.resetPasswordUserID.userID#', timeout = 3000);
		 					
			 				// START: getUserByUserID success?
							
							if ( local.getUserByUserID.statuscode EQ '200 ok' ) {	

								local.getuser = deserializeJSON(local.getUserByUserID.filecontent).dataset[1];
								local.getuserFirstName = local.getuser.userFirstName;
								local.getUserEmail  = local.getuser.userEmail;

								local.email.attributes =structNew();

								//values for email

								structInsert(local.email.attributes,'emailSubject','Your Password Reset is Complete');
								structInsert(local.email.attributes, "emailBody","<p><strong style='font-size:18px;color:red;'>Your Password for #Application.title# has been Reset.</strong></p>
								 				<p>Hello #local.getuserFirstName#,</p>
												<p>Your new password is below:</p>
								 				<p><strong>#local.attributes.newpassword#</strong></p>
								 				#Application.title#<br>
								 				#application.appBaseURL#");
								structInsert(local.email.attributes, "TO", #local.getUserEmail#);
								local.email.attributes = serializeJSON(local.email.attributes);
								local.email.notificationName = 'sendEmailToAny';

								//call /notify/ endpoint POST method with case sendEmailToAny to send email to user

								local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );
								if (local.sendEmail.statusCode EQ '200 Ok') {

									result.status = true;
									result.message = application.messages['controller_post_doResetPassword_success'];   		
										
									return representationOf(result).withStatus(200);

								} else {

									result.status = false;
									result.message = application.messages['controller_post_doResetPassword_error'];
									return representationOf(result).withStatus(500);

								}

		 					} else {

		 					 	result.status = false;
		 					 	result.message = application.messages['controller_post_doResetPassword_usernotfound'];
		 					 	return representationOf(result).withStatus(404);

		 					}
								// END: getUserByUserID success?	
			  				
			 				
							// END: resetUserPassword success?				
		  				
		 		 		} else {

		 		 			result.message = application.messages['controller_post_doResetPassword_error'];
		 		 			result.status  =false;
		 		 			return representationOf(result).withStatus(404);
		 		 		}
						// END: user with this email found?					
		 			}
				</cfscript>
	
			</cfcase>
			<!--- METHOD END:: doResetPassword --->

			<!--- METHOD START:: doForgotPassword --->
			<cfcase value="doForgotPassword">
		  	
			 	<!--- // START: form validation --->
				<cfscript>
				
					// verify if provided email is valid
					if ( NOT isValid("email", arguments.email) ) {
						result.errors = listAppend(result.errors, "email");
						result.errorsForLog = listAppend(result.errorsForLog, "email: #arguments.email#");
					}	
						 
					// START: valid input?
					if ( ListLen(result.errors) GT 0 ) { 
						result['error'] =  "true";
						result.status = false; 
						// local.tmp = application.dataObj.logAction( actionID = 321, extra = result.errorsForLog, cgi = arguments.cgi );
						return representationOf(result).withStatus(500);	
						// Log: 321, 'Reset Password: Invalid Input', 'User submitted invalid input with reset password form', 1
					
					} else {
						local.attributes.filters.SearchUserEmail = arguments.Email;
		 				local.getUserByEmail = httpRequest( methodName = 'GET', endPointOfURL = '/Users/', timeout = 3000, parameters = local.attributes );
		 				
						// START: user with this email found?
						
						if (  local.getUserByEmail.statuscode NEQ '200 OK' ) {
						
							result.message = application.messages['controller_post_doForgotPassword_invalidemail']; 
							result['error'] =  "true";
							result.status = false;
							// Need to Add log action
							return representationOf(result).withStatus(404);

						} else {			
							
							// generate unique ID
							local.rpUID = CreateUUID();
			 				local.getuserDetails = deserializeJSON(local.getUserByEmail.filecontent).dataset[1];
			 				
			 				local.getUserEmail  = local.getuserDetails.userEmail;
			 				local.getUserID     = local.getUserDetails.userID;
			 				local.getuserFirstName = local.getUserDetails.userFirstName;
			 				// invoke method: insertResetPassword
							local.insertResetPassword = application.accountObj.insertResetPassword( 
								email	= arguments.email,
								uuid	= local.rpUID,
								userID  = local.getUserID
							);	

							
			 				// START: success?
							if ( NOT local.insertResetPassword.status ) {
							
								result.message = application.messages['controller_post_doForgotPassword_error'];
								return representationOf(result).withStatus(500);

							} else {
			  					
				 				// update user account (search by email) - add UUID - add requestDateTime
				 				// - insert password reset UID and connect it with an email account
				 				// - send user email with UUID link
				 				//- check user table for 	  					
		  					
								local.email.attributes =structNew();

								//values for email

								structInsert(local.email.attributes,'emailSubject','Request for Password Reset');
								structInsert(local.email.attributes, "emailBody","<p><strong style='font-size:18px;color:red;'>Request for password reset for #Application.title#</strong></p>
									 <br>
									 Hello #local.getuserFirstName#,<br><br>
									 Click the link below to confirm that you wish your password reset.<br><br>
									 <p><a href='#application.appBaseURL#/login/reset/#local.rpUID#'>#application.appBaseURL#/login/reset/#local.rpUID#</a></p>
									 #Application.title#<br>
									 #application.appBaseURL#");
								structInsert(local.email.attributes, "TO", #arguments.email#);
								local.email.attributes = serializeJSON(local.email.attributes);
								local.email.notificationName = 'sendEmailToAny';

								//call /notify/ endpoint POST method with case sendEmailToAny to send email to user

								local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );
							
								if ( local.sendEmail.statusCode EQ '200 Ok') {	

		  							result.status = true;
		  							result['error'] =  "false";
									result.message = application.messages['controller_post_doForgotPassword_success'];									
									// Need to Add log action
									return representationOf(result).withStatus(200);

								} else {

									result.message =application.messages['controller_post_doForgotPassword_error'];
									result['error'] = "true";
									result.status= false;
									// Need to Add log action
									return representationOf(result).withStatus(500);
								}
			  				
			 				}
							// END: success?				
		  				
		 		 		}
						// END: user with this email found?					
		  													
					}
					// END: valid input?

				</cfscript>
						
			</cfcase>
			<!--- METHOD END:: doForgotPassword --->

			<!--- METHOD START:: doBlogPublisherApply --->
			<cfcase value="doBlogPublisherApply">
  	
				<!--- // START: form validation --->
				<cfscript>

					if ( NOT structKeyExists(arguments, 'userid') OR NOT len(arguments.userID) ) { 
			  				result['errors'] = listAppend(result['errors'], "userid");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userid is missing");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message ='userID is required';
						
		  			} 

		  			if ( NOT structKeyExists(arguments, 'auth_token') OR NOT len(arguments.auth_token) ) { 
			  				result['errors'] = listAppend(result['errors'], "auth_token");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "auth_token is missing");
							
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message ='auth_token is required';
						
		  			}
		  			// if ( NOT structKeyExists(arguments, 'blogID') OR NOT len(arguments.blogID) ) { 
			  		// 		result['errors'] = listAppend(result['errors'], "blogID");
							
							// // message: 909 - 'No Record' - 'No valid record provided.'
							// result.message =listAppend(result['message'],'blogID is required');
						
		  			// }

		  			// START: valid input?
		  			if ( ListLen(result.errors) GT 0 ) { 
						result['error'] = "true";
						result.status = false; 
						// Need to Add log action
						return representationOf(result).withStatus(500);

					} else {						
						
						if( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
						
							result['error'] =  "true";
							result.status = false;
							result.message = 'session not available,Please, login to your account first';
							// Need to Add log action
							return representationOf(result).withStatus(404);
						
						} else { 

			  				local.attributes = structNew();
			 	   			// start: valid blog id?
				  			if ( structKeyExists(arguments, 'BlogID') AND len(arguments.blogID)) { 
				  				
								local.attributes.filters.blogID = arguments.blogID;
			  				} 

	 						local.attributes.filters.userID = arguments.userID;
	 						// check if blog belongs to user  
							local.checkUserBlogs = httpRequest(methodName = 'GET', endPointOfURL = '/blogs/', timeout = 3000, parameters =local.attributes );
							local.getCheckUserBlogs = deserializeJSON(local.checkUserBlogs.filecontent).dataset;
							if(local.checkUserBlogs.statuscode NEQ '200 Ok' OR  arraylen(local.getCheckUserBlogs) EQ 0 ) {

								result['error'] = "true";
								result.status = false;
								result.message = application.messages['controller_post_doBlogPublisherApply_invalidblog'];
								// Need to Add log action
								return representationOf(result).withStatus(404); 

			  				} else {

								local.getCheckUserBlogs = deserializeJSON(local.checkUserBlogs.filecontent);
								local.totalCount = local.getCheckUserBlogs.total_count;
								local.getBlogID = "";
								
								for ( local.i=1; local.i LTE arrayLen(local.getCheckUserBlogs.dataset); local.i = local.i + 1 ){

									local.getBlogID = listAppend(local.getBlogID,local.getCheckUserBlogs.dataset[i].blogID);

								}


	 							result.attributes.mode = structNew();
		    					result.attributes.mode = "account";
		  						result.attributes.view = "publisherApply";
		  						result.attributes.blogID = local.getBlogID;
		  						result.message = "success";
		  						result.status  = true;
								// Need to Add log action
		  						return representationOf(result).withStatus(200);
	  							
			  				} // end: blog belongs to user?
		  	  			
						} // end: user logged in?
					
					}// END: valid input?	
				
				</cfscript>
			
			</cfcase>
			<!--- METHOD END:: doBlogPublisherApply --->

			<!--- METHOD START:: doBlogPublisherApplyConfirm --->
			<cfcase value="doBlogPublisherApplyConfirm">
		  	
				<!--- // START: form validation --->
				<cfscript>

					if ( NOT structKeyExists(arguments, 'userid') OR NOT len(arguments.userID) ) { 
			  				result['errors'] = listAppend(result['errors'], "userid");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userID is missing");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message ='userID is required';
						
		  			} 

		  			if ( NOT structKeyExists(arguments, 'blogID') OR NOT len(arguments.blogID) ) { 
			  				result['errors'] = listAppend(result['errors'], "blogID");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "blogID is missing");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message ='blogID is required';
						
		  			}

		  			if ( NOT structKeyExists(arguments, 'auth_token') OR NOT len(arguments.auth_token) ) { 
			  				result['errors'] = listAppend(result['errors'], "auth_token");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "auth_token is missing");
							
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message ='auth_token is required';
						
		  			}

		  			// START: ISvalid Input?
		  			if ( ListLen(result.errors) GT 0 ) { 
						result['error'] =  "true";
						result.status = false; 
						return representationOf(result).withStatus(406);

					} else {

						// start: user logged in?
                        if( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
                        	result['error'] = "true";
							result.status = false; 
							result.message = 'session not available,Please, login to your account first';
							return representationOf(result).withstatus(404);
                   		
                   		} else { 

	 						// check if blog belongs to user  
							// local.checkUserBlogs = application.dataObj.checkUserBlogs( userID = session.user.userID );

							// arguments.attributes.filters.SearchUserID = session.user.userID;
							local.attributes = structNew();
							local.attributes.filters.userID = arguments.userID;

							local.checkUserBlogs = httpRequest( methodName = 'GET', endPointOfURL = '/blogs/', timeout = 3000, parameters = local.attributes );
							local.totalCount = deserializeJSON(local.checkUserBlogs.filecontent).total_count;
						
	 						// start: blog belongs to user?
			  				if ( NOT local.checkUserBlogs.statuscode EQ '200 OK' OR NOT local.totalCount) { 
	 						
								result.message = application.messages['controller_post_doBlogPublisherApplyConfirm_invalidblog']; 
								result.status  = false;
	 							return representationOf(result).withStatus(404);
	 							
			  				} else {
								local.attributes = "";
								local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")#";
								
								// START: loop through arguments.attributes.blogID in case multiple IDs
								for ( local.i=1; local.i LTE ListLen(arguments.blogID); local.i = local.i + 1 ) {
								
									local.thisBlogID = ListGetAt(arguments.blogID,  local.i);

									local.blog.publisherStatusID		=  1;
									local.blog.publisherDateRequested	=  local.timeStamp;
									local.blog.userID 					=  arguments.userID;
									local.blog.auth_token				=  arguments.auth_token;					 				

									local.updateBlog = httpRequest( methodName = 'PUT', endPointOfURL = '/blog/#local.thisBlogID#', timeout = 3000, parameters = local.blog );
					 				// START: updateBlog success?
									
									if ( NOT local.updateBlog.statuscode EQ '200 Ok' ) {
										 							
										result.message = application.messages['controller_post_doBlogPublisherApplyConfirm_error']; 
										result.status  = false;
	 									return representationOf(result).withStatus(500);

									} else {
									
										local.email.attributes = "{
														'emailID'  = '307',
														'TOuserID' = '#arguments.userID#',
														'CCuserID' = '1',
														'userID'   = '1',
														'blogID'   = '#local.thisBlogID#',
														'insertConfirmationCode' = '1'
													    }";

										local.email.notificationName = 'sendEmailToUser';

										local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );

										if( local.sendEmail.statusCode NEQ '200 Ok') {

											result.status = false;
											result.message = 'something went wrong.Please try again later';

											return representationOf(result).withStatus(500);
										}
									}									
									// 260, Publisher: Blog Submitted, User submitted blog to publisher program, 1
    								local.temp = logAction( actionID = 260,  blogID = local.thisBlogID );
									
								} 
								// END: loop through arguments.attributes.blogID in case multiple IDs
									
								// message: 84, Account: Publisher Application Received, Your Publisher Program application has been received., 2, 1
								// result.message = 84;
								result.message = application.messages['controller_post_doBlogPublisherApplyConfirm_success'];
								result.status = true;
								result.attributes.mode = "account";
	  							result.attributes.view = "publisherApplyConfirm";
	  							result.attributes.blogID = arguments.blogID;

	  								

	  							return representationOf(result).withStatus(200);

							}	// END: updateBlog success?						
				  				
		  	  			} // end: user logged in?
		 		
					} // end: blog id?
					
					
				</cfscript>
						
			</cfcase>
			<!--- METHOD END:: doBlogPublisherApplyConfirm --->
			
			<!--- METHOD START:: doInfluencerProgramApply --->
			<cfcase value="doInfluencerProgramApply">
		  	
				<!--- // START: form validation --->
				<cfscript>

					if ( NOT structKeyExists(arguments, 'userid') OR NOT len(arguments.userID) ) { 
			  				result['errors'] = listAppend(result['errors'], "userid");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "userID is missing");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message ='userID is required';
						
		  			}

		  			if ( NOT structKeyExists(arguments, 'auth_token') OR NOT len(arguments.auth_token) ) { 
			  				result['errors'] = listAppend(result['errors'], "auth_token");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "auth_token is missing");
							
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message ='auth_token is required';
						
		  			}

		  			// START: ISvalid Input?
		  			if ( ListLen(result.errors) GT 0 ) { 
						result['error'] =  "true";
						result.status = false; 
						local.temp = logAction( actionID = 909,  extra = result['errorsforlog'] );
						return representationOf(result).withStatus(406);

					} else {

						// start: user logged in?
                        if( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
                        	result['error'] = "true";
							result.status = false; 
							result.message = 'Session not available. Please login to your account first.';
							local.temp = logAction( actionID = 401,  extra = 'Controller/POST functionName: doInfluencerProgramApply authentication failed.' );
							return representationOf(result).withstatus(401);
                   		
                   		} else { 
					   							   		
					   		local.influencerProfileStrenght = application.scoreObj.getInfluencerScore(userID = arguments.userID);
					   		
					   		local.attributes = structNew();
					   		local.attributes.userID 	= arguments.userID;				   		
					   		local.attributes.auth_token = arguments.auth_token;
					   		local.socialMedia = deserializeJSON( httpRequest( methodName = 'GET', endPointOfURL = '/mySocialNetwork', timeout = 3000, parameters = local.attributes ).filecontent );
							
	 						// start: score is at least 50? User connected at least a social media account?
			  				if ( local.influencerProfileStrenght LT 50 OR NOT isDefined("local.socialMedia.status") OR local.socialMedia.status EQ 'false' ) {
	 						
								result.message = "Your Influencer Profile information is incomplete. The last operation was not completed."; 
								result.status  = false;
	 							return representationOf(result).withStatus(404);
	 							
			  				} else {			  				
								
							 	local.user.referrerAppliedDate = "#DateFormat(now(), "YYYY-MM-DD")#";
							 	local.user.influencerStatusID  = 2;
							 	
								local.updateUser = httpRequest( methodName = 'PUT', endPointOfURL = '/user/#arguments.userID#', timeout = 3000, parameters = local.user );								
				 				// START: updateUser success?
									
									// if update was succesfull or not... 
									if ( local.updateUser.statuscode NEQ '200 Ok' ) {
										result.message = application.messages['controller_post_doInfluencerProgramApply_error']; 
										result.status  = false;
	 									return representationOf(result).withStatus(500);

									} else {
									
										local.email.attributes = "{
														'emailID'  = '633',
														'TOuserID' = '#arguments.userID#',
														'CCuserID' = '1',
														'userID'   = '1',
														'blogID'   = '0'
													    }";

										local.email.notificationName = 'sendEmailToUser';

										local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );

										if( local.sendEmail.statusCode NEQ '200 Ok') {

											result.status = false;
											result.message = application.messages['controller_post_doInfluencerProgramApply_error'];

											return representationOf(result).withStatus(500);
										}
									}									
									// '1', 'User submitted influnder profile', 'Influencer: Profile Submitted', '550'
    								local.temp = logAction( actionID = 550, extra = 'Influencer: Profile Submitted' );
									
								// message: 84, Account: Publisher Application Received, Your Publisher Program application has been received., 2, 1
								result.message = application.messages['controller_post_doInfluencerProgramApply_success'];
								result.status = true;							

	  							return representationOf(result).withStatus(200);

							}	// END: updateBlog success?						
				  				
		  	  			} // end: user logged in?
		 		
					} // end: blog id?					
					
				</cfscript>
						
			</cfcase>
			<!--- METHOD END:: doInfluencerProgramApply --->			

			<!--- METHOD START:: doConfirmContestParticipation --->
			<cfcase value="doConfirmContestParticipation">	
	
				<!--- // START: form validation --->
				<cfscript>
						
					if ( NOT structKeyExists(arguments, 'contestWinnerID') OR NOT len(arguments.contestWinnerID) OR NOT isNumeric(arguments.contestWinnerID)) { 

			  				// 381, Contests: Confirm Participation Error, Missing or invalid contestWinnerID, 1
						local.tmp = logAction( actionID = 381, extra = "", cgi = arguments.cgi );
						result['errors'] = listAppend(result['errors'], "contestWinnerID");
						result.message ='contestWinnerID is not valid';
						return representationOf(result).withStatus(406);
						
					} else {
						
						// invoke getContestWinners 
						local.attributes.contestWinnerID = arguments.contestWinnerID;
						local.attributes.functionName = 'getContestWinners';
						local.getContestWinners = httpRequest(methodName = 'GET', endPointOfURL = '/contests/', timeout = 3000, parameters = local.attributes );

						// START: getContestWinners success?
						local.getContestWinnersDetails = deserializeJSON(local.getContestWinners.filecontent).dataset;

						if ( local.getContestWinners.statuscode EQ '200 ok' AND arraylen(local.getContestWinnersDetails) NEQ 0) {

							local.getContestWinnersDetails = deserializeJSON(local.getContestWinners.filecontent).dataset[1];

							if ( getContestWinnersDetails.contestwinnerstatusid NEQ 10 ) { 

								// update contest winner status to Pending Answer
							    local.attributes.contestWinnerID = arguments.contestWinnerID; 
								local.attributes.contestWinnerStatusID = 9;
								local.attributes.functionName = 'updateContestWinnerStatus';

								local.updateContestWinnerStatus = httpRequest(methodName = 'PUT', endPointOfURL = '/contest/', timeout = 3000, parameters = local.attributes );
								local.userID = getContestWinnersDetails.userID;
								local.blogID = getContestWinnersDetails.blogID;
								// email user with account activated confirmation
								local.email.attributes = "{
														'emailID'  = '307',
														'TOuserID' = '#local.userID#',
														'CCuserID' = '1',
														'userID'   = '1',
														'blogID'   = '#local.blogID#',
														'insertConfirmationCode' = '1'
													    }";

								local.email.notificationName = 'sendEmailToUser';

								local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );
								
								if( local.sendEmail.statusCode NEQ '200 Ok') {

									result.status = false;
									result['error'] = "true";
									result.message = application.messages['controller_post_doConfirmContestParticipation_error'];
									return representationOf(result).withStatus(500);
								}	
							
								result['error'] = "false";
								
								// message: 666, Contests: Participation Confirmed, Thank you for confirming your participation in this promotion., 2, 1
								result.status = true;
								result.message = application.messages['controller_post_doConfirmContestParticipation_success'];
								// arguments.attributes.confirmed = true;	
								local.tmp = logAction( actionID = 380, extra = "", cgi = arguments.cgi );
								return representationOf(result).withStatus(200);

							} else {

								result['error'] = "true";
								result.message = application.messages['controller_post_doConfirmContestParticipation_error'];
								local.tmp = logAction( actionID = 382, extra = "", cgi = arguments.cgi );
								return representationOf(result).withStatus(406);

							}

							result['error'] ="true";
							result.message = application.messages['controller_post_doConfirmContestParticipation_error'];
							local.tmp = logAction( actionID = 381, extra = "", cgi = arguments.cgi );
							return representationOf(result).withStatus(406);

						
						} else {

							result['error'] = "true";
							result['errors'] = listAppend(result['errors'], "contestWinnerID");
							result.message =application.messages['controller_post_doConfirmContestParticipation_notfound'];
							result.status = false;
							return representationOf(result).withstatus(404);

						}
						// END: getContestWinners success? 

	 		 		}
					// END: verify if valid UUID
					
					
				</cfscript>
	
			</cfcase>	
			<!--- METHOD END:: doConfirmContestParticipation --->

			<!--- METHOD START:: doDeclineContestParticipation --->
			<cfcase value="doDeclineContestParticipation">	
	
				<!--- // START: form validation --->
				<cfscript>

					if ( NOT structKeyExists(arguments, 'contestWinnerID') OR NOT len(arguments.contestWinnerID) OR NOT isNumeric(arguments.contestWinnerID)) { 
					
			  			// 381, Contests: Confirm Participation Error, Missing or invalid contestWinnerID, 1
						
						result['errors'] = listAppend(result['errors'], "contestWinnerID");
						result.message ='contestWinnerID is not valid';
						
					}

					if ( NOT structKeyExists(arguments, 'contestdeclinereasonID') OR NOT len(arguments.contestdeclinereasonID) OR NOT isNumeric(arguments.contestdeclinereasonID)) { 
					
			  			
						result['errors'] = listAppend(result['errors'], "contestdeclinereasonID");
						result.message ='contestdeclinereasonID is not valid';
					}

					if(listLen(result['errors']) GT 0){

						result['error'] =  "true";
						local.tmp = logAction( actionID = 381, extra = result['errors'], cgi = arguments.cgi );
						return representationOf(result).withStatus(406);

					} else {
							
						// invoke getContestWinners 
						local.attributes.contestWinnerID = arguments.contestWinnerID;
						local.attributes.functionName = 'getContestWinners';
						local.getContestWinners = httpRequest(methodName = 'GET', endPointOfURL = '/contests/', timeout = 3000, parameters = local.attributes );
						local.getContestWinnersDetails = deserializeJSON(local.getContestWinners.filecontent).dataset;


						// START: getContestWinners success?
						if ( local.getContestWinners.statuscode EQ '200 ok' AND ArrayLen(local.getContestWinnersDetails) NEQ 0) {

							local.getContestWinnersDetails = deserializeJSON(local.getContestWinners.filecontent).dataset[1];

							// update contest winner status to Pending Answer
						    local.attributes.contestWinnerID = arguments.contestWinnerID; 
							local.attributes.contestWinnerStatusID = 7;
							local.attributes.functionName = 'updateContestWinnerStatus';

							local.updateContestWinnerStatus = httpRequest(methodName = 'PUT', endPointOfURL = '/contest/', timeout = 3000, parameters = local.attributes );
							
							local.attributes = {};
							local.attributes.contestWinnerID = arguments.contestWinnerID; 
							local.attributes.contestdeclinereasonID = arguments.contestdeclinereasonID;
							local.attributes.functionName = 'updateContestDeclineReasonID';
							// update contest declient ID

							local.updateContestDeclineReasonID = httpRequest(methodName = 'PUT', endPointOfURL = '/contest/', timeout = 3000, parameters = local.attributes );									

							if (local.updateContestDeclineReasonID.statusCode EQ '200 Ok'){

	 							result['error'] = "false";
								
								// message: 668, Contests: Participation Declined, You have declined to participate in this promotion., 2, 1
								result.status = true;
								result.message = application.messages['controller_post_doDeclineContestParticipation_success'];
								return representationOf(result).withStatus(200);
								// arguments.attributes.declined = true;	

							} else {
								result['error'] = 'false';
								result.message  = application.messages['controller_post_doDeclineContestParticipation_error'];
								return representationOf(result).withStatus(500);
							}

						
						} else {
							result['errors'] = listAppend(result['errors'], "contestWinnerID");
							result.message =application.messages['controller_post_doDeclineContestParticipation_notfound'];
							return representationOf(result).withStatus(406);
						}
						// END: getContestWinners success? 

	 		 		}
					// END: verify if valid UUID
					
				</cfscript>
	
			</cfcase>	
			<!--- METHOD END:: doDeclineContestParticipation --->
	
			<!--- METHOD START:: doNotifyParticipantActivity --->
			<cfcase value="doNotifyParticipantActivity">	
	
				<!--- // START: form validation --->
				<cfscript>
			      
			 		// contestActivityURL
			        if ( NOT structKeyExists(arguments,'contestActivityURL')  OR  LEN(TRIM(arguments.contestActivityURL)) EQ 0 OR NOT isValid("URL", arguments.contestActivityURL)) { 
			           
			            result.errors = ListAppend( result.errors, "contestActivityURL");
			            result.message = 'invalid contestActivityURL';
			        }			
					
			 		// contestActivityTypeID
			        if ( NOT structKeyExists(arguments,'contestActivityTypeID') OR arguments.contestActivityTypeID EQ 0  OR LEN(TRIM(arguments.contestActivityTypeID)) EQ 0) { 
			            
			            result.errors = ListAppend( result.errors, "contestActivityTypeID");
			            result.message = 'invalid contestActivityTypeID';
			        }
					 
					// verify if valid UUID
					if ( NOT structKeyExists(arguments,'contestWinnerID') OR NOT isNumeric(arguments.contestWinnerID) OR LEN(TRIM(arguments.contestWinnerID)) EQ 0 ) {
						// 382, Contests: Notify Error, Missing or invalid contestWinnerID, 1
			           
			            result.errors = ListAppend( result.errors, "contestWinnerID");
			            result.message = 'Missing or invalid contestWinnerID';

					}
					
		          	// START: Any Input Errors? --->
		          	if ( Listlen( result.errors) GT 0) { 

		          		 result['error'] = true;
						local.tmp = logAction( actionID = 382, extra =  result.errors, cgi = arguments.cgi );
						return representationOf(result).withStatus(406);

					} else {
						// invoke getContestWinners 
						local.attributes.contestWinnerID = arguments.contestWinnerID;
						local.attributes.functionName = 'getContestWinners';
						local.getContestWinners = httpRequest(methodName = 'GET', endPointOfURL = '/contests/', timeout = 3000, parameters = local.attributes ); 
						local.getContestWinnersDetails = deserializeJSON(local.getContestWinners.filecontent).dataset;
						// START: getContestWinners success?
						if ( local.getContestWinners.statuscode EQ '200 ok' AND ArrayLen(local.getContestWinnersDetails) NEQ 0) {

							local.getContestWinnersDetails = deserializeJSON(local.getContestWinners.filecontent).dataset[1];
				
							if ( local.getContestWinnersDetails.contestWinnerStatusID NEQ 10 ) { 
								// update contest winner status to Pending Answer
								local.insertContestParticipantActivity = application.accountObj.insertContestParticipantActivity( 
									      contestWinnerID = arguments.contestWinnerID, 
										  contestID		  = local.getContestWinnersDetails.contestID,
									 	contestRunID	  = local.getContestWinnersDetails.contestRunID,
											  blogID	  = local.getContestWinnersDetails.blogID,
										  	  userID	  = local.getContestWinnersDetails.userID,
									contestActivityTypeID = arguments.contestActivityTypeID,
									contestActivityURL	  = arguments.contestActivityURL,
									contestActivityText	  = arguments.contestActivityText
								);							
				
								// email user with account activated confirmation
								/* local.sendEmail = application.accountObj.sendEmailToUser( 
									
									emailID  = local.getContestWinnersDetails.emailID_participantConfirmation,
									TOuserID = local.getContestWinnersDetails.userID,
									CCuserID = 1,
									userID   = 1
								
								);
								*/
							
								
								// message: 664, 'Contest: Notification', 'Thank you for notifying us about your activity. Please, come back if you have more activity to report.', 2, 1
								result.status = true;
								result.message = application.messages['controller_post_doNotifyParticipantActivity_success'];
								
								// arguments.attributes.notified = true;	

								return representationOf(result).withstatus(200);

							} else {

								result['error'] ="true";
								result.message =application.messages['controller_post_doNotifyParticipantActivity_error'];
								local.tmp = logAction( actionID = 381, extra = "", cgi = arguments.cgi );
								return representationOf(result).withStatus(406);
							}

						} else {

							result.status = false;
							result['error'] = true;
							result.message = application.messages['controller_post_doNotifyParticipantActivity_notfound'];
							return representationOf(result).withstatus(404);
						}
						// END: getContestWinners success? 

	 		 		}
					// END: Any Input Errors
					
 
				</cfscript>
	
			</cfcase>
			<!--- METHOD END:: doNotifyParticipantActivity --->


			<!--- METHOD START:: doSubmitBlogToPromotion --->
			<cfcase value="doSubmitBlogToPromotion">	
	
			<!--- // START: form validation --->
				<cfscript>
			       
			 		// blogID
			        if (NOT structKeyExists(arguments,'blogID') OR  arguments.blogID EQ 0 OR NOT isNumeric(arguments.blogID) ) { 
					
			        	result.message = 'blogID is Not valid';
			        	result.errors = ListAppend( result.errors, "blogID");
			        	
					}

			 		// verify if valid contestID

					if ( NOT structKeyExists(arguments,'contestID') OR  NOT isNumeric(arguments.contestID) ) {
						// 383, 'Contests: Submit Blog To Promotion Error', 'Missing or invalid parameter', 1
			            result.message = 'contestID is Not valid';
			            result.errors = ListAppend( result.errors, "contestID");

					}

					//userID
					if (NOT structKeyExists(arguments,'userID') OR  arguments.userID EQ 0 OR NOT isNumeric(arguments.userID) ) { 
					
			        	result.message = 'userID is Not valid';
			        	result.errors = ListAppend( result.errors, "userID");
			        	
					}
					//any error?
					if( Listlen(result.errors) GT 0 ) {

						result.status = false;
						result['error'] =  "true";
						local.tmp = logAction( actionID = 383, extra = #result.errors#, cgi = arguments.cgi );
						return representationOf(result).withstatus(406);

					} else {

						local.attributes.filters.userID = arguments.userID;
						local.attributes.filters.blogID = arguments.blogID;
						// check if blog belongs to user  
						local.checkUserBlogs = httpRequest(methodName = 'GET', endPointOfURL = '/blogs/', timeout = 3000, parameters =local.attributes );
						local.checkUserBlogsDetails = deserializeJSON(local.checkUserBlogs.filecontent).dataset;
					
					// start: blog belongs to user?

			  			if (  local.checkUserBlogs.statuscode EQ '200 ok' AND arrayLen(local.checkUserBlogsDetails) NEQ 0) { 

							local.getAvailableContests = application.accountObj.getAvailableContests(contestIsAvailable = 1, userID = arguments.userID );	

								// start: verify contest?
				  			if (NOT local.getAvailableContests.status) { 
							
				        		result['error'] =  "true";
				        		result.errors = ListAppend( result.errors, "contestID");						
								// message: 904, 'Invalid Contest ID', 'The promotion was not found or is no longer available.The last operation was not completed.', 1
								result.message =application.messages['controller_post_doSubmitBlogToPromotion_notfound']; 
								return representationOf(result).withstatus(404);
							} // end: verify contest?				
						
						
							// attributes.errors = local.errors;
			          	
						 	local.attributes = {};
							// insert contest winner record
							local.attributes.contestID 		= arguments.contestID;
							local.attributes.userID 		= arguments.userID;
							local.attributes.contestRunID 	= local.getAvailableContests.query.contestRunID;
							local.attributes.blogID 		= arguments.blogID;
							local.attributes.contestWinnerStatusID = 1;

							local.insertContestWinner = httpRequest(methodName = 'POST', endPointOfURL = '/contests/', timeout = 3000, parameters = local.attributes );
						 
							// START: insertContestWinners success?
							if ( local.insertContestWinner.statuscode EQ '200 Ok' ) {
			 			
								// email user with account activated confirmation
								
								local.email.attributes = "{
															'emailID'  = '#local.getAvailableContests.query.emailID_participantSubmission#',
															'TOuserID' = '#arguments.userID#',
															'CCuserID' = '1',
															'userID'   = '1',
															'blogID'   = '#arguments.blogID#',
															'insertConfirmationCode' = '1'
														    }";

								local.email.notificationName = 'sendEmailToUser';

								local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );

								if( local.sendEmail.statuscode EQ '200 Ok') {

									result['error'] =  "false";
									
									// message: 666, Contests: Participation Confirmed, Thank you for confirming your participation in this promotion., 2, 1
									result.status = true;
									result.message = application.messgaes['controller_post_doSubmitBlogToPromotion_success'];

									return representationOf(result).withStatus(200);
									// arguments.attributes.submittedToPromotion = true;	
								} else {

									result['error'] =  "true";
									
									result.status = false;
									result.message = application.messages['controller_post_doSubmitBlogToPromotion_error'];

									return representationOf(result).withStatus(200);
								}

							}
							// END: contest winner found?
							
						} else {

			        		result['error'] = true;
			        		result.errors = ListAppend( result.errors, "blogID");						
							// message: 903 - 'Invalid Blog ID' - 'Invalid blog ID. The last operation was not completed.'
							result.message = application.messages['controller_post_doSubmitBlogToPromotion_notfound']; 
							return representationOf(result).withstatus(404);

						}// End: blog belongs to user?			
					}
					// END: Any Errors?
		 
				</cfscript>
	
			</cfcase>
			<!--- METHOD END:: doSubmitBlogToPromotion --->

			<!--- METHOD START:: doVerifyBeacon --->
			<cfcase value="doVerifyBeacon">			
			 
				<!--- // START: form validation --->
				<cfscript>

					if ( NOT structKeyExists(arguments, 'userid') OR NOT len(arguments.userID) ) { 

			  				result['errors'] = listAppend(result['errors'], "userid");
							result['errorsForLog'] = listAppend(result['errorsForLog'], "UserID is invalid.");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result['message'] =listAppend(result['message'],'userID is required');
						
		  			} 

		  			if ( NOT structKeyExists(arguments, 'auth_token') OR NOT len(arguments.auth_token) ) { 
			  				result['errors'] = listAppend(result['errors'], "auth_token");
							result['errorsForLog'] = listAppend(result['errorsForLog'], "auth_token is invalid.");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result['message'] =listAppend(result['message'],'auth_token is required');
						
		  			}

		  			if ( listLen(result['errors']) GT 0) { 

						local.tmp =logAction( actionID = 1709, extra = result.errorsForLog, cgi = cgi );
						return representationOf(result).withstatus(404);	
					}


					if( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {

						result['errors'] = listAppend(result['errors'], "user not authorized");
						result.message ='please login first';
						return representationOf(result).withStatus(401);

					} else { 
		 
			   			result['error']  = false;
						result.errors = "";
						result.errorsForLog = "";
						
						local.attributes.filters 			= StructNew();
						local.attributes.filters.UserID	= arguments.userID;
						local.attributes.filters.publisherStatusID = 3;
						local.attributes.filters.isTal = 1;
						
						// local.pagination 		  	= StructNew();
						// local.pagination.offset  	= 1;
						// local.pagination.limit  	= 10;
						// local.pagination.orderCol 	="B.BlogID";
						// local.pagination.orderDir 	="ASC";
						
						// invoke getBlogDetailsByFilter method in dataObj component 
						local.getBlogDetailsByFilter = httpRequest(methodName = 'GET', endPointOfURL = '/blogs/', timeout = 3000, parameters = local.attributes ); 
						local.blogsDetails = deserializeJSON(local.getBlogDetailsByFilter.filecontent).dataset;

					}  		

				</cfscript>

				<cfif local.getBlogDetailsByFilter.statusCode EQ '200 Ok' AND ArrayLen(local.blogsDetails) NEQ 0>
					
					<cfloop array="#local.blogsDetails#" index="thisblogDetails">

						<cfset local.isBeaconFound = false>
						<cfset local.thisBlogID = thisblogDetails.blogID>

						<cfhttp url="#Trim(thisblogDetails.blogURL)#" method="GET" timeout="30" useragent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)"> 
						</cfhttp>

						<cfif NOT DirectoryExists("#application.basePath##application.basePathWeb#/data/blog/")>

							<cfset DirectoryCreate("#application.basePath##application.basePathWeb#/data/blog/")>

						</cfif>

						<cffile action="write" file="#application.basePath##application.basePathWeb#/data/blog/#local.thisBlogID#.html" output="#cfhttp.fileContent#" mode='777'> 
						
						<!--- START: ANALYZE HTML - Find BEACON --->
						<cfif FindNoCase('<script>
							var _comscore = _comscore || [];
							_comscore.push({ c1: "2", c2: "6035233" });
							(function() {
							var s = document.createElement("script"), el = document.getElementsByTagName("script")[0]; s.async = true;
							s.src = (document.location.protocol == "https:" ? "https://sb" : "http://b") + ".scorecardresearch.com/beacon.js";
							el.parentNode.insertBefore(s, el);
							})();
							</script>
							<noscript>
							<img src="http://b.scorecardresearch.com/p?c1=2&c2=6035233&cv=2.0&cj=1" />
							</noscript>', cfhttp.fileContent)>
							<cfset local.isBeaconFound = true>
							
						<cfelseif FindNoCase('<img src="http://b.scorecardresearch.com/p?c1=2&c2=6035233&cv=2.0&cj=1" />', cfhttp.fileContent)>
							
							<cfset local.isBeaconFound = true>
							
						</cfif>
						<!--- END: ANALYZE HTML - Find BEACON --->
						
						<cfscript>
							// start: found?
							if ( NOT local.isBeaconFound ) {
								local.attributes = {};
								// 491, Comsore Beacon: Not Found, The Comscore Beacon was not found on this blog., 1, 1 
								// invoke method: updateBlog
								local.attributes.isBeacon    = 0;
								// local.attributes.userID		= arguments.userID;
								local.updateBlog = httpRequest(methodName = 'PUT', endPointOfURL = '/blog/#local.thisBlogID#', timeout = 3000, parameters = local.attributes ); 

								result.status = false;
								result.message = application.messages['controller_post_doVerifyBeacon_error'];
								return representationOf(result).withstatus(200);

							} else {
								
									local.attributes.isBeacon    = 1;
									// local.attributes.user		= arguments.userID;
								// invoke method: updateBlog
								local.updateBlog = httpRequest(methodName = 'PUT', endPointOfURL = '/blog/#local.thisBlogID#', timeout = 3000, parameters = local.attributes ); 
								
								
								// 490, Comscore Beacon: Found & Verified, The Comscore Beacon has been verified., 2, 1
								result.status = true;
								result.message = application.messages['controller_post_doVerifyBeacon_success'];;
								return representationOf(result).withStatus(200);
									
							} // end: found?	 
			  			</cfscript>
					
					
					</cfloop>

				<cfelse>

					<cfset 	result.status = false>
					<cfset	result.message = application.messages['controller_post_doVerifyBeacon_notfound']>
					<cfset result.error = true>
					<cfreturn representationOf(result).withStatus(200)>

				</cfif>

	 		</cfcase>
			<!--- METHOD END:: doVerifyBeacon --->	 		

	 		<!--- METHOD START:: doConfirmRemoveBlog --->
			<cfcase value="doConfirmRemoveBlog">
		  	   
				<!--- // START: form validation --->
				<cfscript>				

					if ( NOT structKeyExists(arguments, 'userid') OR NOT len(arguments.userID) ) { 
			  				result['errors'] = listAppend(result['errors'], "userid");
							result['errorsForLog'] = listAppend(result['errorsForLog'], "UserID is invalid.");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message =listAppend(result['message'],'userID is required');
						
		  			} 

		  			if ( NOT structKeyExists(arguments, 'auth_token') OR NOT len(arguments.auth_token) ) { 
			  				result['errors'] = listAppend(result['errors'], "auth_token");
							result['errorsForLog'] = listAppend(result['errorsForLog'], "auth_token is invalid.");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message =listAppend(result['message'],'auth_token is required');
						
		  			} 

		  			if ( NOT structKeyExists(arguments, 'blogID') OR NOT len(arguments.blogID) ) { 

		  				result['errors'] = listAppend(result['errors'], "blogID");
						result['errorsForLog'] = listAppend(result['errorsForLog'], "blogID is invalid.");
						// message: 909 - 'No Record' - 'No valid record provided.'
						result.message =listAppend(result['message'],'blogID is required');
						
		  			}

		  			// START: ISvalid Input?
		  			if ( ListLen(result.errors) GT 0 ) { 
						result['error'] = listAppend(result['error'], "true");
						result.status = false; 
						return representationOf(result).withStatus(406);

					} else {

						// start: user logged in?
                        if( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
                        	result['error'] = listAppend(result['error'], "true");
							result.status = false; 
							result.message = 'session not available,Please, login to your account first';
							return representationOf(result).withstatus(401);
                   		
                   		} else { 
			  					
							// check if blog belongs to user 
							local.attributes.filters.userID = arguments.userID;
							local.attributes.filters.blogID = arguments.blogID; 
							local.checkUserBlogs = httpRequest(methodName = 'GET', endPointOfURL = '/blogs/', timeout = 3000, parameters = local.attributes );
							
							// start: blog belongs to user?
							if ( deserializeJSON(local.checkUserBlogs.filecontent).total_count EQ 0 ) { 
								// message: 903 - 'Invalid Blog ID' - 'Invalid blog ID. The last operation was not completed.'
								result.message = application.messages['controller_post_doConfirmRemoveBlog_notdound'] ; 
								result['error'] = listAppend(result['error'], "true");
								result['errors'] = listAppend(result['errors'], "blogID");
								result.status = false;
								return representationOf(result).withStatus(404);

							} else {	  					
	 			 			
								// updateBlog record
								local.attributes = {};
								local.attributes.active 		= '0';
								// local.attributes.userID			= arguments.userID;
								// local.attributes.cgi 			= arguments.cgi;

								local.updateBlog = httpRequest(methodName = 'PUT', endPointOfURL = '/blog/#arguments.blogID#', timeout = 3000, parameters = local.attributes ); 
		 				
					 			// START: updateBlog success?
								if ( local.updateBlog.statuscode NEQ '200 Ok' ) {
									
									// message: 409 - 'Error: Blog Remove' - 'There was an error and the blog was not removed. Please try again.'
									result.message = application.messages['controller_post_doConfirmRemoveBlog_error'];
									result['error'] = true;
									result.status = false;
									return representationOf(result).withStatus(500);

								} else {
								
									// Log : 205 - 'Remove Blog: Success' - User removed a blog.'

									local.tmp = logAction( actionID = 205, cgi = arguments.cgi );
									
									// arguments.attributes.mode   = "account";
				  			// 		arguments.attributes.view   = "manageBlogs";
				  			// 		arguments.attributes.blogID = arguments.attributes.blogID;
									
									// message: 408 - 'Blog Remove: Success' - 'Your blog has been removed successfully.'
									result['error'] = "";
									result['errors'] ="";
									result.status = true;
									result.message = application.messages['controller_post_doConfirmRemoveBlog_success'];
									return representationOf(result).withStatus(200);	
								} // END: updateBlog success?
	  	 		
							} // end: check if blog belongs to user  
		 	 					
				  		} // end: valid blog id?
			 					
			 		} // end: blog id?					

				</cfscript>
						
			</cfcase>
			<!--- METHOD END:: doConfirmRemoveBlog --->			

			<!--- METHOD START:: doContact --->
			<cfcase value="doContact">
				<!--- // START: form validation --->
				<cfscript>
				
				local.attributes = structNew();

					param name="arguments.secret"	type="string" default="";
		  			param name="arguments.response"	type="string" default="";
					param name="arguments.typeID" type="numeric" default="0";
					arrayOfRequiredArguments = listToArray("name,email,question");
	
				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}
				  	
				  	// verify if provided email is valid
					if ( NOT isValid("email", arguments.email) ) {
						result['errors'] = listAppend(result['errors'], "email");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "email: #arguments.email#");
					}	
  			
					// verify name
					if ( len(TRIM(arguments.name)) EQ 0 ) {
						result['errors'] = listAppend(result['errors'], "name");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "name: #arguments.name#");
					}	
					
					// verify subject
					if ( len(TRIM(arguments.question)) EQ 0 ) {
						result['errors'] = listAppend(result['errors'], "question");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "question: #arguments.question#");
					}


					http = new http();

					http.settimeout(3000);

					http.seturl( 'https://www.google.com/recaptcha/api/siteverify' );
					http.setMethod( 'POST' );

					http.addParam(type="formField", name="secret", value="#arguments.secret#");
					http.addParam(type="formField", name="response", value="#arguments.response#");

					returnData = http.send().getPrefix();

					captchaValidation = deserializeJson(returnData.filecontent);

					// Captcha Validation

					if( NOT captchaValidation.success ){
						result['errors'] 		= listAppend(result['errors'],"reCaptcha");
						result['errorsforlog'] 	= listAppend(result['errorsforlog'],"Error While reCaptcha validation.");

					}


				  	
				  	// start: missing parameters?
				  	if ( ListLen(result['errors']) GT 0 ) {
					  	
					  	// 213, 'Error: Invalid Contact Form Input', 'User submitted wrong input in contact form', 1
						local.logAction = logAction( actionID = 213, extra = result['errorsforlog'], cgi = arguments.cgi );
					  	return representationOf(result).withStatus(406);
					
						
					} else { // no errors.. update everything
						 
						// prepare parameters to insert support ticket
						structClear(local.attributes);
						local.attributes.ticketText 		= arguments.question;
						local.attributes.ticketIssueTypeID 	= arguments.typeID;
						local.attributes.ticketName 		= arguments.name; 
						local.attributes.ticketEmail		= arguments.email;
						
						local.insertSupportTicket = httpRequest(methodName = "POST", endPointOfURL = "/tickets/", timeout = 3000, parameters = local.attributes);
					
						// START: insertSupportTicket success? check if the POST endpoint call to /user returned a 200...
						if ( local.insertSupportTicket.status_code NEQ 200 ) {

							result['message'] = application.messages['controller_post_doContact_error'];	 						
							result['errorsforlog'] = listAppend(result['errorsforlog'], "Contact Form: Something went wrong while saving the contact form data");
							// Log - Contact Form: Error - Something went wrong while saving the contact form data
							local.logAction = logAction( actionID = 214, extra = result['errorsforlog'], cgi = arguments.cgi );
							return representationOf(result).withStatus(500); 

						} else {
							
							// Send Email from a support issue To Admin with Ticket Information
							// local.sendSupportEmail = application.accountObj.sendSupportEmail( ticketID = local.insertSupportTicket.ticketID );	
							
							structClear(local.attributes);
							local.email.attributes = structNew();
							structInsert(local.email.attributes,'emailSubject','#Application.title#: Contact Form Received');
							structInsert(local.email.attributes, "TO", '#arguments.email#'); 						
							//values for email
							structInsert(local.email.attributes, "emailBody","<html>
<head>
<title>#Application.title#</title>
</head>
<body style='background-color: white;font-family: Verdana;font-size: 12px;color: black;'>
<p><strong>Thank you for contacting #Application.title#.</strong></p> 
<p>&nbsp;</p>
<p><strong>We will review your question and provide a response within 7 business days.</strong></p>
<p>&nbsp;</p>
<p style='color: orange;font-weight:bold;'><em>#Application.title# Team</em></p>
<p>&nbsp;</p>
</body>
</html>");
							
							local.email.attributes = serializeJSON(local.email.attributes);
							local.email.notificationName = 'sendEmailToAny';

							//call /notify/ endpoint POST method with case sendEmailToAny to send email to user
							local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );


							result['message'] = application.messages['controller_post_doContact_success'];	                			
							// 212, 'Submitted Contact Form', 'User Submitted Contact Form', 1
							local.logAction = logAction( actionID = 212, cgi = arguments.cgi );
							return representationOf(result).withStatus(200);				  					 
								
						} // END: updateUserProfile success?
					
					} // END: any errors?
				</cfscript>			
			
			</cfcase>
			<!--- METHOD END:: doContact --->

			<!--- METHOD START:: doUploadTAL --->			
			<cfcase value="doUploadTAL">
		  	
				<!--- // START: form validation --->
				<cfscript>
					if ( NOT structKeyExists(arguments, 'userid') OR NOT len(arguments.userID) ) { 
		  				result['errors'] = listAppend(result['errors'], "userid");
						result['errorsForLog'] = listAppend(result['errorsForLog'], "UserID is invalid.");
						// message: 909 - 'No Record' - 'No valid record provided.'
						result.message =listAppend(result['message'],'userID is required');
						
		  			} 

		  			if ( NOT structKeyExists(arguments, 'auth_token') OR NOT len(arguments.auth_token) ) { 
			  				result['errors'] = listAppend(result['errors'], "auth_token");
							result['errorsForLog'] = listAppend(result['errorsForLog'], "auth_token is invalid.");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result.message =listAppend(result['message'],'auth_token is required');
						
		  			}

	  				// verify profilePicture
					if ( NOT structKeyExists(arguments, "filePath") OR len(TRIM(arguments.filePath)) EQ 0 ) {
						result.errors = listAppend(result.errors, "filePath");
						result.errorsForLog = listAppend(result.errorsForLog, "TAL missing");
					}	

	  				// START: any errors?
					if ( ListLen(result.errors) GT 0 ) { 
						result['error'] = listAppend(result['error'],'true');
							
						// Log Invalid Input  
						local.tmp =logAction( actionID = 64, extra = result.errorsForLog, cgi = arguments.cgi );
						
						// message: 441 - 'TAL: Invalid Input' - 'You have not provided a valid document file. Please try again'
						result.message = 'TAL: Invalid Input.You have not provided a valid document file. Please try again';
						result.status = false;
						return representationOf(result).withstatus(406);

					} // END: any errors?

		 			// start: user logged in?
		 			if( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
						result['errors'] = listAppend(result['errors'], "user not authorized");
						result.message ='please login first';
						return representationOf(result).withStatus(401);

					} 
		 
				</cfscript>
		 		
					<!--- // START: NO ERRORS? THEN upload --->
				<cfif ListLen(result.errors) EQ 0>	
					
					<!--- <cftry> --->
							
						<!---<cfset local.GUID = CreateUUID()>	--->
							
						<cffile action = "upload" 
			        	  	  fileField = "filePath" 
			        		destination = "#application.basePath#/data/in" 
			         	   nameConflict = "MakeUnique">

						<!--- // START: Image file? --->	
						<cfif NOT ListFindNoCase("jpg,gif,png,doc,docx,pdf,tif,tiff,zip", cffile.serverFileExt)>  

							<cfscript>	

								result['errors'] = listAppend(result.errors, "Profile Picture");
								result.message = application.messages['controller_post_doUploadtal_invalidimage'];
								result.errorsForLog = listAppend(result.errorsForLog, "Profile Picture");
									// Log Invalid Input  
								local.tmp = logAction( actionID = 44, extra = result.errorsForLog, cgi = arguments.cgi );
								
								return representationOf(result).withStatus(406);

							</cfscript>	        
				        
				        <cfelse>

					     	<!--- // START: File Saved? --->
						    <cfif NOT cffile.FILEWASSAVED>   
								<!--- throw error --->
								<cfthrow>  

							<cfelse>
								
								<cfset local.timeStamp = "#DateFormat(now(), "YYYYMMDD")##TimeFormat(now(), "HHMMSS")#">
						 			<cfif NOT directoryExists("#application.basePath#/data/tals/")>
						 				<cfset directorycreate("#application.basePath#/data/tals/")>
						 			</cfif>
						 		<!--- rename? --->
							    <cffile 	 
							    	 action = "rename" 
					  				 source = "#application.basePath#/data/in/#cffile.serverFile#" 
					  			destination = "#application.basePath#/data/tals/TAL_#arguments.UserID#_#local.timeStamp#.#cffile.serverFileExt#">	
								 
								<cfscript>	
			 						// insert TAL record
									local.insertTAL = application.dataObj.insertTAL( 
										fileName  = "TAL_#arguments.UserID#_#local.timeStamp#.#cffile.serverFileExt#", 
											 user = arguments.userID,
										 	  cgi = arguments.cgi
									);
													 			// START: insertTAL success?
									if ( NOT local.insertTAL.status ) {
										throw();
									} else {	
										
										// writeDump(local.insertTAL);
										
										// START: loop through arguments.attributes.blogID in case multiple IDs
										local.attributes = {};
										for ( local.i=1; local.i LTE ListLen(arguments.blogID); local.i = local.i + 1 ) {
										
											local.thisBlogID = ListGetAt(arguments.blogID,  local.i);
										
											// invoke method: updateBlog
											
											local.attrbutes.isTal   = 1;
											// local.attributes.userID	= arguments.userID;
											
											local.updateBlog = httpRequest(methodName = 'PUT', endPointOfURL = '/blog/#local.thisBlogID#', timeout = 3000, parameters = local.attributes ); 

										}; // END: Loop through blogID
										if ( local.updateBlog.statuscode EQ '200 Ok') {
											// Log - 270, Publisher: TAL Upload - Success, TAL file uploaded successfully., 1
											local.tmp = logAction( actionID = 270, extra = result.errorsForLog, cgi = arguments.cgi );
											
											// message: 440 - 'TAL: Uploaded' - 'Your traffic assignment letter was uploaded successfully.'
											result.message = application.messages['controller_post_doUploadtal_success'];
											retult.status = true;	
											return representationOf(result).withstatus(200);

										} else {

											result.message = application.messages['controller_post_doUploadtal_error'];
											retult.status = false;	
											return representationOf(result).withstatus(500);

										}
									}				
									// END: insertImage success?
			 
								</cfscript> 
				
							</cfif>  	
							<!--- // END: File Saved? ERROR --->   
			 	         	   
				        </cfif> 
				        <!--- // END: Image file? ---> 	   
			 		
						
				 		<!--- <cfcatch>
					
							<cfscript>	
								// Log Upload Error
								local.tmp = application.dataObj.logAction( actionID = 45, extra = local.errorsForLog, cgi = arguments.cgi );
								
								// message: 443 - 'TAL: Error' - 'There was a problem with the document upload. Please try again.'
								result.message = 443;
							</cfscript>	
						
						</cfcatch>
					</cftry> --->
				
				</cfif>
				<!--- // END: NO ERRORS? THEN upload --->
					
		 	</cfcase>
		 	<!--- METHOD END:: doUploadTAL --->

		 	<!---
		 	<!--- METHOD START:: doProgramChange --->
			<cfcase value="doProgramChange">

				<!--- // START: form validation --->
				<cfscript>
					// verify userid
					if ( NOT structKeyExists(arguments, 'userid') OR NOT len(arguments.userID) ) { 
		  				result['errors'] = listAppend(result['errors'], "userid");
						// message: 909 - 'No Record' - 'No valid record provided.'
						result['errorsForLog'] = listAppend(result['errorsForLog'], "UserID is invalid.");						
		  			} 

		  			// verify auth_token
		  			if ( NOT structKeyExists(arguments, 'auth_token') OR NOT len(arguments.auth_token) ) { 
			  				result['errors'] = listAppend(result['errors'], "auth_token");
							// message: 909 - 'No Record' - 'No valid record provided.'
							result['errorsForLog'] = listAppend(result['errorsForLog'], "auth_token is invalid.");
		  			}

					// verify program
					if ( NOT structKeyExists(arguments, 'programID') ) { 
						result['errors'] = listAppend(result.errors, "programID");
						result['errorsForLog'] = listAppend(result.errorsForLog, "programID missing");
					} else {
					
						if ( len(TRIM(arguments.programID)) EQ 0 ) {
							result['errors'] = listAppend(result.errors, "programID");
							result['errorsForLog'] = listAppend(result.errorsForLog, "programID: blank");
						}		 
					}

					// verify blogID
					if ( NOT structKeyExists(arguments, 'blogID') ) { 
						result['errors'] = listAppend(result.errors, "blogID");
						result['errorsForLog'] = listAppend(result.errorsForLog, "blogID missing");
					} else {
					
						if ( NOT isNumeric(arguments.blogID) ) {
							result['errors'] = listAppend(result.errors, "blogID");
							result['errorsForLog'] = listAppend(result.errorsForLog, "blogID: not numeric");
						}			 
					}
							
					// enroll or opt out
					if ( NOT structKeyExists(arguments, 'programAction') ) {

						result['errors'] = listAppend(result.errors, "programAction");
						result['errorsForLog'] = listAppend(result.errorsForLog, "programAction missing");

					} else {
					
						if (  arguments.programAction EQ 'in' ) {
							 local.isEnrolled = 1; // in
							 local.actionID	  = 940;
						} else {
							 local.isEnrolled = 0; // out
							 local.actionID	  = 942;
						}			 
					}
		 
			 		// START: any errors?
					if ( ListLen(result.errors) GT 0 ) { 
						
						result.error = true;
						// Log - Profile: Invalid Input - User entered invalid profile input
						local.tmp = logAction( actionID = 231, extra = result.errorsForLog, cgi = arguments.cgi );
						return representationOf(result).withstatus(406);

					} else {

						// start: user logged in?
			 			if( NOT isAuth( userID = arguments.userID, auth_token = arguments.auth_token ) ) {
							result['errors'] = listAppend(result['errors'], "user not authorized");
							result.message ='please login first';
							return representationOf(result).withStatus(401);

						} else { 

							// get program details
							local.attributes.programID = arguments.programID;

							local.getProgram = httpRequest(methodName = 'GET', endPointOfURL = '/program/', timeout = 3000, parameters = local.attributes ); 
							
							// START: program found?
							if ( local.getProgram.status_code NEQ 200 ) {

								result.status = false;
								result.message = 'Unable Get programs for Given programID';
								result['error'] = listAppend(result['error'],'programID');
								result['errorsforlog'] = listAppend(result['errorsforlog'],'programID not valid');

								return representationOf(result).withStatus(404);

							} else {
								
								// Set local vars
								local.thisBlogID 	  = arguments.blogID;
								local.thisPublisherID = arguments.userID;
								local.thisUserID 	  = arguments.userID;
								local.isUpdateAdUnits = true; // flag - used to update ad units or not depending on status of blog (suspended/applied) and program
								local.isPending		  = 0; // default - not pending
								// local.isEnrolled	  = 1; // default - enroll blog
		
								// set filters
								local.attributes = structNew();
								local.attributes.filters.BlogID  	= local.thisBlogID;
								local.attributes.filters.UserID  	= local.thisPublisherID;
								local.attributes.filters.ProgramID  = arguments.programID;
		
								local.getBlogProgramsByFilters =  httpRequest(methodName = 'GET', endPointOfURL = '/programs/', timeout = 3000, parameters = local.attributes );
															
								local.isFound = ( local.getBlogProgramsByFilters.status_code EQ 200 )? true : false; // set isFound flag if the record already exists in the blog program table
								
								// *******
								// AD Unit and Content Topic program? Assign Topic ID to site ad units
								local.getProgramdetails = deserializeJSON(local.getProgram.filecontent).dataset[1];
								if ( local.getProgramdetails .contentTopicID > 0 ) {

									local.attributes = {};
									// get site ID
									local.attributes.userID 	= local.thisUserID;
									local.attributes.blogID  	= local.thisBlogID;
									local.attributes.auth_token = arguments.auth_token;
									
									local.getPublisherMeta = httpRequest(methodName = 'GET', endPointOfURL = '/publishersMeta/', timeout = 3000, parameters = local.attributes );
									
									// START: publisher meta found?
									if ( local.getPublisherMeta.statuscode NEQ '200 Ok'  ) {
										
										result.error = true;										
										// message: '563', 'Program: Update Error', 'There was an error while updating the blog(s) program record(s)', '1'
									    result.message = 'Program: Update Error.There was an error while updating the blog(s) program record(s)';
										return representationOf(result).withStatus(500);

									} else {

										// set program ad unit from query above
										local.adUnitName = local.getProgramdetails.meta_key;

										local.getPublisherMetaDetails = deserializeJSON(local.getPublisherMeta.fileContent);										
										
										// START: ad unit found in publisher meta? proceed to update ad unit on ad server
										if ( StructKeyExists(local.getPublisherMetaDetails.publishers_Meta, local.adUnitName) ) {
											
											local.adUnitID = local.getPublisherMetaDetails.publishers_Meta[local.adUnitName];
											 
											// get ad units associated with this site
											local.listAdUnits = application.openXObj.openX_listAdUnits( site_uid = local.getPublisherMetaDetails.publishers_Meta.site_uid );
											
											// START: AD units found?
											if ( local.listAdUnits.status ) {

												// loop through ad units
												for ( local.u=1; local.u LTE ArrayLen(local.listAdUnits.response.objects); local.u = local.u + 1 ) {	
													local.thisAdUnitstruct = local.listAdUnits.response.objects[local.u];

													// START: Match meta ad unit to program ad unit
													if ( local.thisAdUnitStruct["id"] == local.adUnitID ) {

														// START: Enroll or opt-out? Associate or De-associate?
														if ( local.isEnrolled == 0 ) {

															// Remove Program Content Topic
															StructDelete(local.thisAdUnitStruct["content_topics"], local.getProgram.query.contentTopicID);
															local.useContentTopicsList = StructKeyList(local.thisAdUnitStruct["content_topics"]);

															// writedump(local.useContentTopicsList);

															// DISassociate program content topic from Ad Unit
															local.openX_updateAdUnit = application.openXObj.openX_updateAdUnit(
																uid 	   		= local.thisAdUnitStruct["uid"],
																name	 	   	= local.thisAdUnitStruct["name"],
																content_topics 	= local.useContentTopicsList
															);
														
															// START: de-associate content topic success?
															if ( NOT local.openX_updateAdUnit.status ) {
																local.error = true; 
															} // END: de-associate content topic success?

														} else {

															// START: Check if Content Topic already there? If not, then add it
															if ( NOT StructKeyExists(local.thisAdUnitstruct["content_topics"], local.getProgram.query.contentTopicID) ) {
															
																// Add Program Content Topic ID to list
																local.useContentTopicsList = StructKeyList(local.thisAdUnitStruct["content_topics"]);
																
																// writeOutput('local.getProgram.query.contentTopicID: #local.getProgram.query.contentTopicID#<br/>');
																
																local.useContentTopicsList = ListAppend(local.useContentTopicsList, local.getProgram.query.contentTopicID);
																
																// writeOutput('local.useContentTopicsList: #local.useContentTopicsList#<br/>');
															
																// Asssociate Program content topic id too Ad Unit
																local.openX_updateAdUnit = application.openXObj.openX_updateAdUnit(
																	uid 	  		= local.thisAdUnitStruct["uid"],
																	name	 	   	= local.thisAdUnitStruct["name"],
																	content_topics 	= local.useContentTopicsList
																	
																);
															
																// START: associate content topic success?
																if ( NOT local.openX_updateAdUnit.status ) {
																	local.error = true; 
																} // END: associate content topic success?
															
															}; // END: Check if Content Topic already there? If not, then add it															
															
														}; // END: Enroll or opt-out? Associate or De-associate?
															
													}; // END: Match meta ad unit to program ad unit
													
												}; // END: loop through ad units						
					
											}; // END: AD units found?
											 
										}; // END: AD unit found in publisher meta? proceed to update ad unit on ad server
				
									}; // END: publisher meta found?
				
								}; // END: Ad Unit and Content Topic Program?	
								// ******				

								// START: final check on error
								if ( !local.error ) {
								
									// START: update or insert?
									if ( NOT local.isFound ) { // INSERT 
			
										// INSERT
										userID 		 = local.thisPublisherID;
										blogID 		 = local.thisBlogID;
										programID 	 = arguments.attributes.programID;
										siteStatusID = local.getProgram.query.defaultProgSiteStatusID;
										active	 	 = 1;
										
										local.insertBlogProgram =  httpRequest(methodName = 'POST', endPointOfURL = '/programs/', timeout = 3000, parameters = local.attributes );
			
										// START: insertBlogProgram success?
										if ( local.insertBlogProgram.status ) {
											// Log
											local.tmp = application.dataObj.logAction( actionID = local.actionID, blogID = local.thisBlogID, userID = session.user.userID, cgi = arguments.cgi );
											local.status = true;
										} else {
											local.status = false;
										}
										// END: updateUserProfile success?
			
									} else { // UPDATE
			
										// START: Enroll or opt-out?
										if ( local.isEnrolled == 1 ) { // Need to be enrolled? Set to default program status
											local.siteStatusID = local.getProgram.query.defaultProgSiteStatusID;
										} else {
											local.siteStatusID = 6; // Publisher opted out
										}// END: Enroll or opt-out?
										
										// update blog program
										local.attributes = structNew();
										local.attributes.userID		  = local.thisPublisherID;
										local.attributes.blogID  	  = local.thisBlogID;
										local.attributes.programID 	  = arguments.attributes.programID;
										local.attributes.siteStatusID = local.siteStatusID;
										local.attributes.active	 	  = 1;

										local.updateBlogProgram =  httpRequest(methodName = 'PUT', endPointOfURL = '/program/', timeout = 3000, parameters = local.attributes );
			
										// START: updateBlogProgram success?
										if ( local.updateBlogProgram.status_code EQ 200 ) {
											// Log
											local.tmp = application.dataObj.logAction( actionID = local.actionID, blogID = local.thisBlogID, userID = session.user.userID, cgi = arguments.cgi );
											local.status = true;
										} else {
											local.status = false;
										} // END: updateUserProfile success?				
			
									} // END: update or insert?
			
								} // END: final check on error							

							} // END: program found?


							// Error? Enrolled or Opted Out?
							if ( !local.status ) {
								// message: '563', 'There was an error while changing the selected blog(s) program enrollment status', '2', '1'
								local.message = 563;
							} else {
							
								if ( local.isEnrolled == 1 ) { // Enrolled
									// message: '560', 'Program: Blog Enrolled', 'The selected blog(s) have been enrolled in the program.', '2', '1'
									local.message = 560;
								} else {
									// message: '564', 'Program: Blog Opt-Out', 'The selected blog(s) have been removed from the program.', '1', '1'
									local.message = 564;
								}
							}
							
							result.message = local.message;

			 			} // end: user logged in?

			 		} // END: any errors?

					arguments.attributes.error  = local.error;
					arguments.attributes.errors = local.errors;

				</cfscript>
				
				<!--- <cfdump var="#local#"> --->				

			</cfcase>
			<!--- METHOD END:: doProgramChange --->
			 --->

			<!--- METHOD START:: doWebToLead --->
			<cfcase value="doWebToLead">

				<!--- // START: form validation --->
				<cfscript>

				param name="arguments.phone" 		type="string" default="";
				param name="arguments.comments" 	type="string" default="";

				// verify firstname				
				if ( NOT structKeyExists(arguments, 'first_name') ) { 
					result['errors'] = listAppend(result.errors, "first_name");
					result['errorsForLog'] = listAppend(result.errorsForLog, "first_name missing");
				} else {
				
					if ( len(TRIM(arguments.first_name)) EQ 0 ) {
						result['errors'] = listAppend(result.errors, "first_name");
						result['errorsForLog'] = listAppend(result.errorsForLog, "first_name: blank");
					}		 
				}
				
				// verify lastname
				if ( NOT structKeyExists(arguments, 'last_name') ) { 
					result['errors'] = listAppend(result.errors, "last_name");
					result['errorsForLog'] = listAppend(result.errorsForLog, "last_name missing");
				} else {
				
					if ( len(TRIM(arguments.last_name)) EQ 0 ) {
						result['errors'] = listAppend(result.errors, "last_name");
						result['errorsForLog'] = listAppend(result.errorsForLog, "last_name: blank");
					}		 
				}

				// verify companyName
				if ( NOT structKeyExists(arguments, 'company') ) { 
					result['errors'] = listAppend(result.errors, "company");
					result['errorsForLog'] = listAppend(result.errorsForLog, "companyName missing");
				} else {
				
					if ( len(TRIM(arguments.company)) EQ 0 ) {
						result['errors'] = listAppend(result.errors, "company");
						result['errorsForLog'] = listAppend(result.errorsForLog, "companyName: blank");
					}		 
				}				
	 			
				// verify if provided email is valid
				if ( NOT structKeyExists(arguments, 'email') ) { 
					result['errors'] = listAppend(result.errors, "email");
					result['errorsForLog'] = listAppend(result.errorsForLog, "email missing");
				} else {
				
					if ( NOT isValid("email", arguments.email) ) {
						result['errors'] = listAppend(result.errors, "email");
						result['errorsForLog'] = listAppend(result.errorsForLog, "email: invalid");
					}		 
				}				
	 
				</cfscript>
				
	 			<!--- // start: any errors? --->
				<cfif ListLen(result.errors) GT 0>
				
					<cfscript>
						result.error = true; 
						// 213, 'Error: Invalid Contact Form Input', 'User submitted wrong input in contact sales form', 1
						local.tmp = logAction( actionID = 213, extra = result.errorsForLog, cgi = arguments.cgi );
						result.message = application.messages['controller_post_doWebToLead_error'];
						return representationOf(result).withStatus(406);
					</cfscript>
				
				<cfelse>

					<cfscript>
						
						// prepare parameters to insert support ticket
						local.attributes = structNew();
						local.attributes.ticketText 		=  'Company: #arguments.company#<br/> Phone: #arguments.phone#<br/> Comments: #arguments.comments#';
						local.attributes.ticketIssueTypeID 	= 8;
						local.attributes.ticketName 		= arguments.first_name&' '&arguments.last_name;
						local.attributes.ticketEmail		= arguments.email;
						
						local.insertSupportTicket = httpRequest(methodName = "POST", endPointOfURL = "/tickets/", timeout = 3000, parameters = local.attributes);

						if ( local.insertSupportTicket.status_code NEQ 200 ) {

							result.message = application.messages['controller_post_doWebToLead_error'];						
							result['errorsforlog'] = listAppend(result['errorsforlog'], "Contact Form: Something went wrong while saving the contact form data");
							// Log - Contact Form: Error - Something went wrong while saving the contact form data
							local.logAction = logAction( actionID = 214, extra = result['errorsforlog'], cgi = arguments.cgi );
							return representationOf(result).withStatus(500); 

						}

					</cfscript>
				
					<cfhttp url="https://www.salesforce.com/servlet/servlet.WebToLead?encoding=UTF-8" method="POST" timeout="30" result="local.toSalesForce"  getAsBinary="never">
						<cfhttpparam type="formField" 	name="oid" 		value="00Di0000000hliY">
						<cfhttpparam type="formField" 	name="retURL" 	value="http://www.foodieblogroll.com/contact/success">
						
						<cfhttpparam type="formField" 	name="submit" 		value="submit">
						
						<cfhttpparam type="formField" 	name="email" 		value="#arguments.email#">
						
						<cfhttpparam type="formField" 	name="first_name" 	value="#arguments.first_name#">
						<cfhttpparam type="formField" 	name="last_name" 	value="#arguments.last_name#">
						
						<!--- <cfhttpparam type="formField" 	name="industry" 	value="#arguments.industry#">
						<cfhttpparam type="formField" 	name="URL" 			value="#arguments.URL#"> --->
						<cfhttpparam type="formField" 	name="company" 		value="#arguments.company#">
						<!--- <cfhttpparam type="formField" 	name="country_code" value="#arguments.country_code#"> --->
						<cfhttpparam type="formField" 	name="phone" 		value="#arguments.phone#">
						<!--- <cfhttpparam type="formField" 	name="city" 		value="#arguments.city#">
						<cfhttpparam type="formField" 	name="title" 		value="#arguments.title#"> --->
						
						<!--- <cfhttpparam type="formField" 	name="00Ni000000BIqLQ" 		value="#arguments.interested_in#">
						<cfhttpparam type="formField" 	name="00Ni000000BIqLV" 		value="#arguments.timing#">
						<cfhttpparam type="formField" 	name="00Ni000000BIqLG" 		value="#arguments.budget#">
						<cfhttpparam type="formField" 	name="00Ni000000CMfve" 		value="#arguments.comments#"> --->
						
					</cfhttp>

					<cfscript>

						// 212, 'Submitted Contact Form', 'User Submitted Contact Form', 1
						local.tmp = logAction( actionID = 212, cgi = arguments.cgi );						
						result.status  = true;
						result.message = application.messgaes['controller_post_doWebToLead_success'];
						return representationOf(result).withStatus(200);

					</cfscript>
				
				</cfif>
				<!--- // END: any errors? --->
		  
			</cfcase>			
			<!--- METHOD END:: doWebToLead --->


			<cfcase value="doContactSales">

			<!--- // START: form validation --->

				<cfscript>
				
					result.error  = false;
					result.errors = "";
					result.errorsForLog = "";
		  			
		  			param name="arguments.secret"	type="string" default="";
		  			param name="arguments.response"	type="string" default="";
					// verify firstname
					if ( NOT structKeyExists(arguments,'name') OR len(TRIM(arguments.name)) EQ 0 ) {

						result.error = listAppend(result.error, "name");
						result.errors =listAppend(result.errors, "name is missing");
						result.errorsForLog = listAppend(result.errorsForLog, "name: #arguments.name#");

						
					}
		 
					// verify companyName
					if (  NOT structKeyExists(arguments,'companyName') OR len(TRIM(arguments.companyName)) EQ 0 ) {

						result.error = listAppend(result.error, "companyName");
						result.errors = listAppend(result.errors, "companyName is missing");
						result.errorsForLog = listAppend(result.errorsForLog, "name: #arguments.companyName#");

					}
					
					
					// verify if provided email is valid
					if ( NOT structKeyExists(arguments,"email")  OR len(TRIM(arguments.email)) EQ 0  ) {

						result.error = listAppend(result.error, "email");
						result.errors = listAppend(result.errors, "email is missing");
						result.errorsForLog = listAppend(result.errorsForLog, "email: #arguments.email#");

					}

					if( structKeyExists(arguments,"email") AND NOT isValid("email", arguments.email) ) {

						result.error = listAppend(result.error, "email");
						result.errors = listAppend(result.errors, "email is not valid");
						result.errorsForLog = listAppend(result.errorsForLog, "email: #arguments.email#");
					}
		 
					// verify question
					if ( NOT structKeyExists(arguments,"comments") OR len(TRIM(arguments.comments)) EQ 0 ) {

						result.errors = listAppend(result.errors, "comments");
						result.errorsForLog = listAppend(result.errorsForLog, "comments: #arguments.comments#");

					} 
		 			

					

					http = new http();

					http.settimeout(3000);

					http.seturl( 'https://www.google.com/recaptcha/api/siteverify' );
					http.setMethod( 'POST' );

					http.addParam(type="formField", name="secret", value="#arguments.secret#");
					http.addParam(type="formField", name="response", value="#arguments.response#");

					returnData = http.send().getPrefix();

					captchaValidation = deserializeJson(returnData.filecontent);

					// Captcha Validation

					if( NOT captchaValidation.success ){
						result['errors'] 		= listAppend(result['errors'],"reCaptcha");
						result['errorsforlog'] 	= listAppend(result['errorsforlog'],"Error While reCaptcha validation.");

					}
				

		 			// start: any errors?
					if ( ListLen(result.errors) GT 0 ) { 

						result.error = true; 
					
						// 213, 'Error: Invalid Contact Form Input', 'User submitted wrong input in contact sales form', 1
						local.tmp = logAction( actionID = 213, extra = result.errorsForLog );
						result.message = 'please submit valid data in contact sales form';
						return representationOf(result).withstatus(406);

					} else {
					
		 
		            	// Insert Lead into DB  --->
		           		local.insertLead = application.accountObj.insertLead( 
							     						
						  	leadQuestion 	 = arguments.comments, 
						    leadFirstName    = arguments.name,
						 	leadCompanyName  = arguments.companyName,
						 	leadEmail        = arguments.email,
						 	leadPhoneWork    = arguments.phone
							
						);		
		 
					  
						// 212, 'Submitted Contact Form', 'User Submitted Contact Form', 1
						local.tmp = logAction( actionID = 212, cgi = arguments.cgi );

						// START : Success insertSupportTicket --->	 	       
						if ( local.insertLead.status ) {	 	       
						 	       
							local.sendEmailToAny = application.accountObj.sendEmailToAny( 
								emailFrom = "#application.salesEmail#",
								senderName = "Sales",
								emailSubject = "#variables.title#: Contact Sales Form Received",				
								emailBody = "
										<html>
										<head>
										<title>#variables.title#</title>
										</head>
										<body style='background-color: white;font-family: Verdana;font-size: 12px;color: black;'>
										<p><strong>Hi #arguments.name#,</strong></p>
										<p>&nbsp;</p>
										<p><strong>Thank you for contacting The #variables.title# Sales Team.</strong></p> 
										<p>&nbsp;</p>
										<p><strong>We will review your submission and provide a response within 7 business days.</strong></p>
										<p>&nbsp;</p>
										<table>
											<tr> 
												<td><b> Name :</b></td>
												<td> #arguments.name# </td>
											</tr>
											<tr> 
												<td><b> Email :</b></td>
												<td> #arguments.email# </td>
											</tr>
											<tr> 
												<td><b> Company Name :</b></td>
												<td> #arguments.companyName# </td>
											</tr>
											<tr> 
												<td><b> Phone :</b></td>
												<td> #arguments.phone# </td>
											</tr>
											<tr> 
												<td><b> Comments :</b></td>
												<td> #arguments.comments# </td>
											</tr>
											<tr> 
												<td><b> Date / Time :</b></td>
												<td> #DateTimeFormat(now(), 'yyyy/MM/dd   HH:nn:ss')# </td>
											</tr>
										</table>
										<p>&nbsp;</p>
										<p style='color: orange;font-weight:bold;'><em>The #variables.title# Sales Team</em></p>
										<p>&nbsp;</p>
										</body>
									</html>",
								TO = arguments.email,
								CC = application.salesEmail
														
							);		
					
						} else {

							result.error = true;
							result.message = application.messages['controller_post_doContactSales_error'];
							return representationOf(result).withStatus(406);

						}
						
						result.status  = true;
						result.message = application.messages['controller_post_doContactSales_success'];
						return representationOf(result).withStatus(200);

					}
					// end: any errors?

				</cfscript>
  
			</cfcase>

			<!--- METHOD START:: doRequestInvite --->
			<cfcase value="doRequestInvite">
				<!--- // START: form validation --->
				<cfscript>

				param name="arguments.blogUrl" type="string" default="";
				param name="arguments.blogTitle" type="string" default="";

				local.attributes = structNew();

					
					arrayOfRequiredArguments = listToArray("name,email,comments");
	
				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}
				  	// verify if provided email is valid
					if ( NOT isValid("email", arguments.email) ) {
						result['errors'] = listAppend(result['errors'], "email");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "email: #arguments.email#");
					}	
  			
					// verify name
					if ( len(TRIM(arguments.name)) EQ 0 ) {
						result['errors'] = listAppend(result['errors'], "name");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "name: #arguments.name#");
					}			
					

					if ( structKeyExists(arguments, "secret") AND structKeyExists(arguments, "response") ) {
						
						http = new http();

						http.settimeout(3000);

						http.seturl( 'https://www.google.com/recaptcha/api/siteverify' );
						http.setMethod( 'POST' );

						http.addParam(type="formField", name="secret", value="#arguments.secret#");
						http.addParam(type="formField", name="response", value="#arguments.response#");

						returnData = http.send().getPrefix();

						captchaValidation = deserializeJson(returnData.filecontent);

						// Captcha Validation

						if( NOT captchaValidation.success ){
							result['errors'] 		= listAppend(result['errors'],"reCaptcha");
							result['errorsforlog'] 	= listAppend(result['errorsforlog'],"Error While reCaptcha validation.");

						}

					} else {

						result['errors'] 		= listAppend(result['errors'],"reCaptcha");
						result['errorsforlog'] 	= listAppend(result['errorsforlog'],"Error While reCaptcha validation.");

					}
				  	
				  	// start: missing parameters?
				  	if ( ListLen(result['errors']) GT 0 ) {
					  	
					  	// 213, 'Error: Invalid Contact Form Input', 'User submitted wrong input in contact form', 1
						local.logAction = logAction( actionID = 213, extra = result['errorsforlog'], cgi = arguments.cgi );
					  	return representationOf(result).withStatus(406);
					
						
					} else { // no errors.. update everything
						 
						// prepare parameters to insert support ticket
						structClear(local.attributes);						
						local.attributes.ticketText 		= "Blog/Site URL: #arguments.blogUrl# 
															   Blog/Site Title: #arguments.blogTitle# 
															   #arguments.comments# ";
						local.attributes.ticketIssueTypeID 	= 13;
						local.attributes.ticketName 		= arguments.name; 
						local.attributes.ticketEmail		= arguments.email;
						
						local.insertSupportTicket = httpRequest(methodName = "POST", endPointOfURL = "/tickets/", timeout = 3000, parameters = local.attributes);
					
						// START: insertSupportTicket success? check if the POST endpoint call to /user returned a 200...
						if ( local.insertSupportTicket.status_code NEQ 200 ) {

							result['message'] = application.messages['controller_post_doRequestInvite_error'];	 						
							result['errorsforlog'] = listAppend(result['errorsforlog'], "Contact Form: Something went wrong while saving the contact form data");
							// Log - Contact Form: Error - Something went wrong while saving the contact form data
							local.logAction = logAction( actionID = 214, extra = result['errorsforlog'], cgi = arguments.cgi );
							return representationOf(result).withStatus(500); 

						} else {
							
							// Send Email from a support issue To Admin with Ticket Information
							// local.sendSupportEmail = application.accountObj.sendSupportEmail( ticketID = local.insertSupportTicket.ticketID );	
							
							structClear(local.attributes);
							local.email.attributes = structNew();
							structInsert(local.email.attributes,'emailSubject','#Application.title#: Recipe Contributor Invite Request Received');
							structInsert(local.email.attributes, "TO", '#arguments.email#'); 						
							//values for email
							structInsert(local.email.attributes, "emailBody","<html>
											<head>
											<title>#Application.title#</title>
											</head>
											<body style='background-color: white;font-family: Verdana;font-size: 12px;color: black;'>
											<p><strong>Thank you for contacting #Application.title#.</strong></p> 
											<p>&nbsp;</p>
											<p><strong>We will review your question and provide a response within 7 business days.</strong></p>
											<p>&nbsp;</p>
											<p style='color: orange;font-weight:bold;'><em>#Application.title# Team</em></p>
											<p>&nbsp;</p>
											</body>
											</html>"
										);
																		
							local.email.attributes = serializeJSON(local.email.attributes);
							local.email.notificationName = 'sendEmailToAny';

							//call /notify/ endpoint POST method with case sendEmailToAny to send email to user
							local.sendEmail = httpRequest(methodName = 'POST', endPointOfURL = '/notify/', timeout = 3000, parameters = local.email );


							result['message'] = application.messages['controller_post_doRequestInvite_success'];	                			
							// 212, 'Submitted Contact Form', 'User Submitted Contact Form', 1
							local.logAction = logAction( actionID = 216, cgi = arguments.cgi );
							return representationOf(result).withStatus(200);				  					 
								
						} // END: updateUserProfile success?
					
					} // END: any errors?
				</cfscript>			
			
			</cfcase>
			<!--- METHOD END:: doRequestInvite --->

		</cfswitch>

	</cffunction>
	
</cfcomponent>