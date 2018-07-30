<cfcomponent extends="taffyAPI.base" taffy:uri="/mySocialNetwork/" hint="used to Activate Publisher Account.">

	<cffunction name="GET" access="public" hint="Return User Social DATA" output="false" auth='true'>
		<cfargument name="UserID" 		type="numeric" 	required="yes" hint="User ID">
		<cfargument name="auth_token" 	type="string" 	required="yes" hint="Authentication Token">

 		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message']	= ''>
		<cfset local.resultFacebook   = {} >
		<cfset local.resultTwitter    = {} >
		<cfset local.resultGooglePlus = {} >
		<cfset local.resultInstagram  = {} >
		<cfset local.resultPinterest  = {} >
 
		<cftry>

	  		<cfquery datasource="#variables.datasource#" name="local.socialTypes">

				SELECT 
					* 
					FROM social_login sl
					LEFT JOIN val_socialtype vs ON sl.socialLoginTypeID = vs.socialTypeID
	 				WHERE 	sl.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.UserID#">
	 					AND vs.active = 1				
	 			
			</cfquery>			

			<cfloop query="local.socialTypes">

				<cfif socialLoginTypeID EQ 4 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialFacebook">
						
						SELECT 
							slf.*,sl.socialLoginTypeID,sl.isMainAccount
							FROM social_login_facebook slf
								INNER JOIN social_login sl ON sl.socialLoginUserID = slf.facebookUserID
								WHERE facebookUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>

					<cfif local.socialFacebook.recordCount EQ 1 >

						<cfset structInsert( local.resultFacebook, "socialtypename", "facebook" )>
						<cfset structInsert( local.resultFacebook, "socialid", local.socialFacebook.facebookUserID )>
						<cfset structInsert( local.resultFacebook, "name", local.socialFacebook.name )>
						<cfset structInsert( local.resultFacebook, "accesstoken", local.socialFacebook.access_token )>
						<cfset structInsert( local.resultFacebook, "link", local.socialFacebook.link )>
						<cfset structInsert( local.resultFacebook, "connectstatus", local.socialFacebook.connectedStatus )>
						<cfset structInsert( local.resultFacebook, "ismainaccount", local.socialFacebook.isMainAccount )>
						<cfset structInsert( local.resultFacebook, "sociallogintypeid", local.socialFacebook.socialLoginTypeID )>

					</cfif>

				</cfif>

				<cfif local.socialTypes.socialLoginTypeID EQ 13 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialTwitter">
						
						SELECT 	slt.*,
								sl.socialLoginTypeID,
								sl.isMainAccount 
							FROM 
								social_login_twitter slt 
								INNER JOIN social_login sl ON sl.socialLoginUserID = slt.twitterUserID
							WHERE twitterUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>

					<cfif local.socialTwitter.recordCount EQ 1 >
						
						<cfset structInsert( local.resultTwitter, "socialtypename", "twitter" )>
						<cfset structInsert( local.resultTwitter, "socialid", local.socialTwitter.twitterUserID )>
						<cfset structInsert( local.resultTwitter, "name", local.socialTwitter.name )>
						<cfset structInsert( local.resultTwitter, "accesstoken", local.socialTwitter.access_token )>
						<cfset structInsert( local.resultTwitter, "followers", local.socialTwitter.followers_count)>
						<cfset structInsert( local.resultTwitter, "friendsCount", local.socialTwitter.friends_count)>
						<cfset structInsert( local.resultTwitter, "listedCount", local.socialTwitter.listed_count)>
						<cfset structInsert( local.resultTwitter, "statusesCount", local.socialTwitter.statuses_count)>
						<cfset structInsert( local.resultTwitter, "link", local.socialTwitter.profile_location )>
						<cfset structInsert( local.resultTwitter, "connectstatus", local.socialTwitter.connectedStatus )>
						<cfset structInsert( local.resultTwitter, "ismainaccount", local.socialTwitter.isMainAccount )>
						<cfset structInsert( local.resultTwitter, "sociallogintypeid", local.socialTwitter.socialLoginTypeID )>

					</cfif>

				</cfif>

				<cfif local.socialTypes.socialLoginTypeID EQ 16 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialInstagram">
						
						SELECT 
							sli.*,
							sl.socialLoginTypeID,
							sl.isMainAccount
							FROM social_login_instagram sli
								INNER JOIN social_login sl ON sl.socialLoginUserID = sli.instagramUserID
								WHERE instagramUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>

					<cfif local.socialInstagram.recordCount EQ 1 >
						
						<cfset structInsert( local.resultGooglePlus, "socialtypename", "instagram" )>
						<cfset structInsert( local.resultGooglePlus, "socialid", local.socialInstagram.instagramUserID )>
						<cfset structInsert( local.resultGooglePlus, "name", local.socialInstagram.username )>
						<cfset structInsert( local.resultGooglePlus, "accesstoken", local.socialInstagram.access_token )>
						<cfset structInsert( local.resultGooglePlus, "followers", local.socialInstagram.count_follows )>
						<cfset structInsert( local.resultGooglePlus, "followedbycount", local.socialInstagram.count_followed_by )>
						<cfset structInsert( local.resultGooglePlus, "mediaCount", local.socialInstagram.count_media )>
						<cfset structInsert( local.resultGooglePlus, "link", local.socialInstagram.website )>
						<cfset structInsert( local.resultGooglePlus, "connectstatus", local.socialInstagram.connectedStatus )>
						<cfset structInsert( local.resultGooglePlus, "ismainaccount", local.socialInstagram.isMainAccount )>
						<cfset structInsert( local.resultGooglePlus, "sociallogintypeid", local.socialInstagram.socialLoginTypeID )>

					</cfif>

				</cfif>


				<cfif local.socialTypes.socialLoginTypeID EQ 17 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialgoogle">
						
						SELECT 
							slg.*,
							sl.socialLoginTypeID,
							sl.isMainAccount
							FROM social_login_google slg
								INNER JOIN social_login sl ON sl.socialLoginUserID = slg.id
								WHERE id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>

					<cfif local.socialgoogle.recordCount EQ 1 >

						<cfset structInsert( local.resultInstagram, "socialtypename", "google" )>
						<cfset structInsert( local.resultInstagram, "socialid", local.socialgoogle.id )>
						<cfset structInsert( local.resultInstagram, "name", local.socialgoogle.displayName )>
						<cfset structInsert( local.resultInstagram, "accesstoken", local.socialgoogle.access_token )>
						<cfset structInsert( local.resultInstagram, "link", local.socialgoogle.url )>
						<cfset structInsert( local.resultInstagram, "connectstatus", local.socialgoogle.connectedStatus )>
						<cfset structInsert( local.resultInstagram, "ismainaccount", local.socialgoogle.isMainAccount )>
						<cfset structInsert( local.resultInstagram, "sociallogintypeid", local.socialgoogle.socialLoginTypeID )>
						<cfset structInsert( local.resultInstagram, "followers", local.socialgoogle.followers_count )>

					</cfif>

				</cfif>

				<cfif socialLoginTypeID EQ 15 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialPinterest">
						
						SELECT 
							slf.*,sl.socialLoginTypeID,sl.isMainAccount
							FROM social_login_pinterest slf
								INNER JOIN social_login sl ON sl.socialLoginUserID = slf.pinterestUserID
								WHERE pinterestUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>

					<cfif local.socialPinterest.recordCount EQ 1 >

						<cfset structInsert( local.resultPinterest, "socialtypename", "pinterest" )>
						<cfset structInsert( local.resultPinterest, "socialid", local.socialPinterest.PinterestUserID )>
						<cfset structInsert( local.resultPinterest, "name", local.socialPinterest.username )>
						<cfset structInsert( local.resultPinterest, "accesstoken", local.socialPinterest.access_token )>
						<!--- <cfset structInsert( local.resultPinterest, "link", local.socialPinterest.link )> --->
						<cfset structInsert( local.resultPinterest, "connectstatus", local.socialPinterest.connectedStatus )>
						<cfset structInsert( local.resultPinterest, "ismainaccount", local.socialPinterest.isMainAccount )>
						<cfset structInsert( local.resultPinterest, "sociallogintypeid", local.socialPinterest.socialLoginTypeID )>

					</cfif>

				</cfif>

			</cfloop>

			<cfset result.dataset = [] >			
			
			<cfif NOT structIsEmpty(local.resultFacebook) >
				<cfset arrayAppend(result.dataset, local.resultFacebook)>				
			</cfif>
			<cfif NOT structIsEmpty(local.resultTwitter)>
				<cfset arrayAppend(result.dataset, local.resultTwitter)>				
			</cfif>
			<cfif NOT structIsEmpty(local.resultGooglePlus)>
				<cfset arrayAppend(result.dataset, local.resultGooglePlus)>				
			</cfif>
			<cfif NOT structIsEmpty(local.resultInstagram)>
				<cfset arrayAppend(result.dataset, local.resultInstagram)>				
			</cfif>

			<cfif NOT structIsEmpty(local.resultPinterest)>
				<cfset arrayAppend(result.dataset, local.resultPinterest)>				
			</cfif>

			<cfcatch>
		      	<!--- :: degrade gracefully :: --->
		     	<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
		       
		     	<!--- // 666, 'Database Error', 1 --->
				<cfset logAction( actionID = 666, extra = "method: /mySocialNetwork/{userID}/GET", errorCatch = variables.cfcatch  )>	
				<cfreturn representationOf(result.message).withStatus(500)>
			  
	        </cfcatch>
			
	    </cftry>

	    <!--- // Found? --->		
		<cfif NOT arrayIsEmpty(result.dataset)>
			<cfset result.status = true />
		</cfif>

	    <cfset result.message = application.messages['mysocialNetwork_get_found_success']>
	    <cfset logAction( actionID = 666, extra = "method: /mySocialNetwork/{userID}/GET", extra = "successfully listed the users social logins."  )>
 		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

	<cffunction name="POST" access="public" hint="Link the social details" output="false" auth="true" >
		<cfargument name="socialType"	 type="string" 	required="yes" hint="socialNetworkName such as facebook,twitter, etc.,">		
		<cfargument name="socialDetails" type="string" 	required="yes" hint="social details">
		<cfargument name="UserID" 		 type="numeric" required="yes" hint="User ID">
		<cfargument name="auth_token"	 type="string" 	required="yes" hint="Authentication Token">

 		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['errors'] = "" />
		<cfset result['errorsforlog'] = "" />
		<cfset result['status']  	= false />
		<cfset result['message']    = ''>

 		<cfset structAppend( arguments, deserializeJson( arguments.socialDetails ) )>	
		<cftry>

		<cfswitch expression="#arguments.socialType#">

			<!--- 
				1. facebook
				2. twitter
				3. instagram
				4. google
				5. pinterest

			 --->
			
			<cfcase value="facebook">

				<cfscript>	

					arrayOfRequiredArguments = listToArray("facebookUserID,access_token,userID,email");

				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}

					param name="arguments.first_name" 		 type="string"  default="" ;
		  			param name="arguments.last_name" 		 type="string"  default="" ;		  			
		  			param name="arguments.gender" 			 type="string"  default="" ;
		  			param name="arguments.link" 			 type="string"  default="" ;
		  			param name="arguments.locale" 			 type="string"  default="" ;
		  			param name="arguments.timezone" 		 type="string"  default="" ;
		  			param name="arguments.updated_time" 	 type="string"  default="" ;
		  			param name="arguments.verified" 		 type="string"  default="" ;
		  			param name="arguments.profile_image_url" type="string"  default="" ;
		  			param name="arguments.expiry_time" 		 type="string"  default="" ;
		  			param name="arguments.connectedStatus" 	 type="numeric" default="1" ;

		  			if ( ListLen(result['errors']) GT 0 ) { 

						result['error'] = true;

						// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1

						local.logAction = logAction( actionID = 312, extra = result['errorsforlog'] );
						
						return representationOf(result).withStatus(401);

					} else {

						local.attributes = {};
						local.attributes.facebookUserID = arguments.facebookUserID;
						
						existingUserDetails = httpRequest( methodName = 'GET', endPointOfURL = '/facebook', timeout = 3000, parameters = local.attributes );
						
						if( existingUserDetails.status_code EQ 500 ){

							result['message'] = application.messages['mysocialNetwork_post_facebook_error'];
							result.status = false;
							return representationOf(result).withStatus(500);

						}

						facebookUserDetail = deserializeJSON( existingUserDetails.fileContent );
						
						if( existingUserDetails.status_code EQ 200 AND arrayLen(facebookUserDetail.dataset) ) {

							if(	arguments.userID EQ facebookUserDetail.dataset[1].userID ) {

								structClear(local.attributes);

								local.attributes.socialLoginUserID 	= arguments.facebookUserID;
								local.attributes.accessToken 		= arguments.access_token;
								local.attributes.connectedStatus 	= arguments.connectedStatus;
								local.attributes.socialLoginType 	= 'facebook';					

								updateConnectStatus  = httpRequest( methodName = 'PUT', endPointOfURL = '/mySocialNetwork', timeout = 3000, parameters = local.attributes );
								local.facebookUserID = arguments.facebookUserID;

								result['message'] = application.messages['mysocialNetwork_post_facebook_success'];
	                		
	                			result.status = true;

							} else {

								result.status = false;
								result['message'] = application.messages['mysocialNetwork_post_facebook_alreadyconnected'];
								return representationOf(result).withStatus(406);
							}
							

						} else {
							
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
							
	                		local.facebookUserID = userDetailsFB.dataset[1].facebookUserID;
	                		result['message'] = application.messages['mysocialNetwork_post_facebook_success'];
	                		
	                		result.status = true;

	                		application.accountObj.insertSocialUserLogin( userID = arguments.userid, socialLoginTypeID = 4, socialLoginUserID = local.facebookUserID, isMainAccount = 0 );

	                	}
                		
                	}
		  			</cfscript>

		  			<cfquery name="result.query" datasource="#variables.datasource#" >
		  				
		  				SELECT 
		  					* 
		  					FROM 
		  						social_login_facebook
		  					WHERE
		  						facebookUserID = <cfqueryparam value="#local.facebookUserID#" cfsqltype="cf_sql_varchar">
		  			</cfquery>
    				
            		<cfreturn representationOf(result).withStatus(200) />

	  		</cfcase>

	  		<cfcase value="twitter">

				<cfscript>	

					arrayOfRequiredArguments = listToArray("email,twitterUserID,name,screen_name,access_token_secret");

				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
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
		  			param name="arguments.connectedStatus" 	 	type="numeric"  default="1" ;

		  			if ( ListLen(result['errors']) GT 0 ) { 

						result['error'] = true;
						// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1
						local.logAction = logAction( actionID = 312, extra = result['errorsforlog'] );
						
						return representationOf(result).withStatus(401);

					} else {

						local.attributes = {};
	                 	local.attributes.twitterUserID = arguments.twitterUserID;

						existingUserDetails = httpRequest( methodName = "GET", endPointOfURL = "/twitter", timeout = 3000, parameters = local.attributes );

						if( existingUserDetails.status_code EQ 500 ){

							result['message'] = application.messages['mysocialNetwork_get_twitter_error'];
							result.status = false;
							return representationOf(result).withStatus(500);

						}

						twitterUserDetail = deserializeJSON(existingUserDetails.filecontent);

						if( existingUserDetails.status_code EQ 200 AND arrayLen(twitterUserDetail.dataset) ) {
							
							if( arguments.userID EQ twitterUserDetail.dataset[1].userID ) {

								structClear(local.attributes);
							
								local.attributes.socialLoginUserID 	= arguments.twitterUserID;
								local.attributes.accessToken 		= arguments.access_token;
								local.attributes.connectedStatus 	= arguments.connectedStatus;
								local.attributes.socialLoginType 	= 'twitter';					

								updateConnectStatus = httpRequest( methodName = 'PUT', endPointOfURL = '/mySocialNetwork', timeout = 3000, parameters = local.attributes );
								local.twitterUserID = arguments.twitterUserID;

								result['message'] = application.messages['mysocialNetwork_post_twitter_success'];
	                			result.status = true;

							} else {

								result.status = false;
								result['message'] = application.messages['mysocialNetwork_post_twitter_alreadyconnected'];
								return representationOf(result).withStatus(406);
							}
							

						} else {

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

	                		userDetailsTW = deserializeJSON(createTwitterUser.fileContent);

	                		local.twitterUserID = userDetailsTW.dataset[1].twitterUserID;
	                		application.accountObj.insertSocialUserLogin( userID = arguments.userID, socialLoginTypeID = 13, socialLoginUserID = local.twitterUserID, isMainAccount = 0 );	                		                		
	                		result['message'] = application.messages['mysocialNetwork_post_twitter_success'];
	                		result.status = true;
	                	}
                		
                	}
		  			</cfscript>

		  			<cfquery name="result.query" datasource="#variables.datasource#" >
		  				
		  				SELECT 
		  					* 
		  					FROM 
		  						social_login_twitter
		  					WHERE
		  						twitterUserID = <cfqueryparam value="#local.twitterUserID#" cfsqltype="cf_sql_varchar">
		  			</cfquery>

		  			
    				
            		<cfreturn representationOf(result).withStatus(200) />

	  		</cfcase>

	  		<cfcase value="instagram">

				<cfscript>	

					arrayOfRequiredArguments = listToArray('email,instagramUserID,username,access_token');

				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}

					param name="arguments.bio"			 		type="string"	 default="";
					param name="arguments.website" 		 		type="string"	 default="";
					param name="arguments.profile_picture" 		type="string"	 default="";
					param name="arguments.full_name" 		 	type="string"	 default="";
					param name="arguments.count_media" 			type="numeric"	 default="0";
					param name="arguments.count_followed_by" 	type="numeric"	 default="0";
					param name="arguments.count_follows" 		type="numeric" 	 default="0";
					param name="arguments.connectedStatus" 	 	type="numeric"   default="1";					

					if( ListLen(result['errors']) GT 0  ) {
						result['error'] = true;
						
						// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1
						local.logAction = logAction( actionID = 312, extra = result['errorsforlog'] );
						
						return representationOf(result).withStatus(401);
					
					} else {

						local.attributes 	= {};
						local.attributes.instagramUserID = arguments.instagramUserID;
						
						existingUserDetails = httpRequest( methodName ='GET', endPointOfURL='/instagram', timeout = 3000, parameters = local.attributes);

						if( existingUserDetails.status_code EQ 500 ){

							result['message'] = application.messsages['mysocialNetwork_post_instagram_error'];
							result.status = false;
							return representationOf(result).withStatus(500);

						}

						instagramUserDetail = deserializeJSON(existingUserDetails.filecontent);

						if(existingUserDetails.status_code EQ 200 AND arrayLen(instagramUserDetail.dataset)) {

							if ( arguments.userID EQ instagramUserDetail.dataset[1].userID ) {

								structClear(local.attributes);

								local.attributes.socialLoginUserID 	= arguments.instagramUserID;
								local.attributes.accessToken 		= arguments.access_token;
								local.attributes.connectedStatus 	= arguments.connectedStatus;
								local.attributes.socialLoginType 	= 'instagram';					
								
								result['message'] 	= application.messages['mysocialNetwork_post_instagram_alreadyconnected'];
								updateConnectStatus = httpRequest( methodName = 'PUT', endPointOfURL = '/mySocialNetwork', timeout = 3000, parameters = local.attributes );
								local.instagramUserID = arguments.instagramUserID;

								result['message'] = application.messages['mysocialNetwork_post_instagram_success'];
                				result.status = true;

							} else {

								result['message'] = application.messages['mysocialNetwork_post_instagram_alreadyconnected'];
								result.status = false;
								return representationOf(result).withStatus(406);
							}
							

						} else {

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
								createInstagramUser  = httpRequest(methodName = "POST", endPointOfURL = "/instagram", timeout = 3000, parameters = local.attributes);
								
								userDetailsInstagram = deserializeJSON(createInstagramUser.fileContent);
								
								local.instagramUserID  = userDetailsInstagram.dataset[1].instagramUserID;		                		
                				application.accountObj.insertSocialUserLogin( userID = arguments.userID, socialLoginTypeID = 16, socialLoginUserID = local.instagramUserID, isMainAccount = 0 );
                				result['message'] = application.messages['mysocialNetwork_post_instagram_success'];
                				result.status = true;

		                	} 

                	}
		  			</cfscript>

		  			<cfquery name="result.query" datasource="#variables.datasource#" >
		  				
		  				SELECT 
		  					* 
		  					FROM 
		  						social_login_instagram
		  					WHERE
		  						instagramUserID = <cfqueryparam value="#local.instagramUserID#" cfsqltype="cf_sql_varchar">
		  			</cfquery>

            		<cfreturn representationOf(result).withStatus(200) />

	  		</cfcase>

	  		<cfcase value="google">

				<cfscript>	

					arrayOfRequiredArguments = listToArray('emails,id,displayName,access_token');

				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}

					param name="arguments.id_token"			 	type="string"	 default="";
					param name="arguments.session_state" 		type="string"	 default="";
					param name="arguments.gender"		 		type="string"	 default="";
					param name="arguments.image_url" 		 	type="string"	 default="";
					param name="arguments.language" 			type="string"	 default="";
					param name="arguments.url" 					type="string"	 default="";
					param name="arguments.followers_count"		type="numeric"   default=0;
					param name="arguments.connectedStatus"		type="numeric"   default=1;

					if( ListLen(result['errors']) GT 0  ) {
						result['error'] = true;
						
						// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1
						local.logAction = logAction( actionID = 312, extra = result['errorsforlog'] );
						
						return representationOf(result).withStatus(401);
					
					} else {

						local.attributes 	= {};
						local.attributes.id = arguments.id;
						
						existingUserDetails = httpRequest( methodName ='GET', endPointOfURL='/googleplus/', timeout = 3000, parameters = local.attributes);

						if( existingUserDetails.status_code EQ 500 ){

							result['message'] = application.messages['mysocialNetwork_post_google_error'];
							result.status = false;
							return representationOf(result).withStatus(500);

						}
						
						googlePlusUserDetail = deserializeJSON(existingUserDetails.filecontent);

						if(existingUserDetails.status_code EQ 200 AND arrayLen(googlePlusUserDetail.dataset)) {

							if( arguments.userID EQ googlePlusUserDetail.dataset[1].userID ) {

								structClear(local.attributes);

								local.attributes.socialLoginUserID 	= arguments.id; 
								local.attributes.accessToken 		= arguments.access_token;
								local.attributes.connectedStatus 	= arguments.connectedStatus;
								local.attributes.socialLoginType 	= 'google';

								result['message'] 	= application.messages['mysocialNetwork_post_google_alreadyconnected'];
								updateConnectStatus = httpRequest( methodName = 'PUT', endPointOfURL = '/mySocialNetwork', timeout = 3000, parameters = local.attributes );							
								local.googlePlusUserID = arguments.id;
								result['message'] = application.messages['mysocialNetwork_post_google_success'];
								result.status = true;
								
							} else {

								result['message'] = application.messages['mysocialNetwork_post_google_alreadyconnected'];
								result.status = false;
								return representationOf(result).withStatus(406);
							}
							
							
						} else {

								structClear(local.attributes);

								local.attributes.id 				 = arguments.id;
								local.attributes.emails 			 = arguments.emails;
								local.attributes.displayName 		 = arguments.displayName;
								local.attributes.access_token 		 = arguments.access_token;
								local.attributes.id_token 			 = arguments.id_token;
								local.attributes.session_state 		 = arguments.session_state;
								local.attributes.gender 			 = arguments.gender;
								local.attributes.image_url 	 		 = arguments.image_url;
								local.attributes.language 			 = arguments.language;
								local.attributes.url 			 	 = arguments.url;
								local.attributes.followers_count     = arguments.followers_count;
								local.attributes.connectedStatus     = arguments.connectedStatus;

								// a new googleplus user using POST function of googleplus API endpoint.
								createGooglePlusUser 		 = httpRequest(methodName = "POST", endPointOfURL = "/googlePlus/", timeout = 3000, parameters = local.attributes);
								userDetailsGooglePlus		 = deserializeJSON(createGooglePlusUser.fileContent);

								
								local.googlePlusUserID 	 = userDetailsGooglePlus.dataset[1].id;
								application.accountObj.insertSocialUserLogin( userID = arguments.userID, socialLoginTypeID = 17, socialLoginUserID = local.googlePlusUserID, isMainAccount = 0 );
								result['message'] = application.messages['mysocialNetwork_post_google_success'];
								result.status = true;
		                	} 

                		
                	}
		  			</cfscript>

		  			<cfquery name="result.query" datasource="#variables.datasource#" >
		  				
		  				SELECT 
		  					* 
		  					FROM 
		  						social_login_google
		  					WHERE
		  						id = <cfqueryparam value="#local.googlePlusUserID#" cfsqltype="cf_sql_varchar">
		  			</cfquery>

            		<cfreturn representationOf(result).withStatus(200) />

	  		</cfcase>

	  		<cfcase value="pinterest">
				<cfscript>	

					arrayOfRequiredArguments = listToArray("pinterestUserID,access_token,userID");

				  	for( element in arrayOfRequiredArguments ) {
				  		if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
				  	}

					param name="arguments.username" 			type="string"  default="" ;
					param name="arguments.first_name" 			type="string"  default="" ;
		  			param name="arguments.last_name" 			type="string"  default="" ;		  			
		  			param name="arguments.bio"	 				type="string"  default="" ;
		  			param name="arguments.pins_count" 			type="numeric" default="0";
					param name="arguments.following_count" 		type="numeric" default="0";
					param name="arguments.followers_count" 		type="numeric" default="0";
					param name="arguments.boards_count" 		type="numeric" default="0";
					param name="arguments.likes_count" 			type="numeric" default="0";		  			
		  			param name="arguments.profile_image_url"	type="string"  default="" ;
		  			param name="arguments.connectedStatus" 	 	type="numeric" default="1" ;

		  			if ( ListLen(result['errors']) GT 0 ) { 

						result['error'] = true;

						// Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1

						local.logAction = logAction( actionID = 312, extra = result['errorsforlog'] );
						
						return representationOf(result).withStatus(401);

					} else {

						local.attributes = {};
						local.attributes.pinterestUserID = arguments.pinterestUserID;
						
						existingUserDetails = httpRequest( methodName = 'GET', endPointOfURL = '/pinterest', timeout = 3000, parameters = local.attributes );
						
						if( existingUserDetails.status_code EQ 500 ){

							result['message'] = application.messages['mysocialNetwork_post_pinterest_error'];
							result.status = false;
							return representationOf(result).withStatus(500);

						}

						pinterestUserDetail = deserializeJSON( existingUserDetails.fileContent );

						if( existingUserDetails.status_code EQ 200 AND arrayLen(pinterestUserDetail.dataset) ) {

							if(	arguments.userID EQ pinterestUserDetail.dataset[1].userID ) {

								structClear(local.attributes);

								local.attributes.socialLoginUserID 	= arguments.pinterestUserID;
								local.attributes.accessToken 		= arguments.access_token;
								local.attributes.connectedStatus 	= arguments.connectedStatus;
								local.attributes.socialLoginType 	= 'pinterest';					

								updateConnectStatus  = httpRequest( methodName = 'PUT', endPointOfURL = '/mySocialNetwork', timeout = 3000, parameters = local.attributes );
								local.pinterestUserID = arguments.pinterestUserID;
								
								result['message'] = application.messages['mysocialNetwork_post_pinterest_success'];
	                		
	                			result.status = true;

							} else {

								result.status = false;
								result['message'] = application.messages['mysocialNetwork_post_pinterest_alreadyconnected'];
								return representationOf(result).withStatus(406);
							}
							

						} else {
							
							structClear(local.attributes);

	                		local.attributes.pinterestUserID 		= arguments.pinterestUserID;
	                		local.attributes.username				= arguments.username;
	                		local.attributes.first_name 			= arguments.first_name;
							local.attributes.last_name				= arguments.last_name;
							local.attributes.bio 					= arguments.bio;
							local.attributes.pins_count 			= arguments.pins_count;
							local.attributes.following_count		= arguments.following_count;
							local.attributes.followers_count		= arguments.followers_count;
							local.attributes.boards_count 			= arguments.boards_count;
							local.attributes.likes_count 			= arguments.likes_count;
							local.attributes.profile_image_url 		= arguments.profile_image_url;
							local.attributes.access_token 			= arguments.access_token;
							local.attributes.connectedStatus 		= arguments.connectedStatus;

							//create a new PIN user.
	                		createPINUser = httpRequest( methodName = "POST", endPointOfURL = '/pinterest', timeout = 3000, parameters = local.attributes );

	                		userDetailsPIN = deserializeJSON(createPINUser.fileContent);
							
	                		local.pinterestUserID = userDetailsPIN.dataset[1].pinterestUserID;
	                		result['message'] = application.messages['mysocialNetwork_post_pinterest_success'];
	                		
	                		result.status = true;

	                		application.accountObj.insertSocialUserLogin( userID = arguments.userid, socialLoginTypeID = 15, socialLoginUserID = local.pinterestUserID, isMainAccount = 0 );

	                	}
                		
                	}
		  			</cfscript>

		  			<cfquery name="result.query" datasource="#variables.datasource#" >
		  				
		  				SELECT 
		  					* 
		  					FROM 
		  						social_login_pinterest
		  					WHERE
		  						pinterestUserID = <cfqueryparam value="#local.pinterestUserID#" cfsqltype="cf_sql_varchar">
		  			</cfquery>
    				
            		<cfreturn representationOf(result).withStatus(200) />

	  		</cfcase>

  		</cfswitch>
	  
				 
			<cfcatch>
		      	<!--- :: degrade gracefully :: --->		      
		    	<cfset result.message = errorMessage( message ='database_query_error', error = variables.cfcatch )>
		     	<!--- // 666, 'Database Error', 1 --->
				<cfset logAction( actionID = 666, extra = "method: /mySocialNetwork/{userID}/POST", errorCatch = variables.cfcatch  )>	
				<cfreturn representationOf(result.message).withStatus(500)>
			  
	        </cfcatch>
			
	    </cftry>

	</cffunction>

	<cffunction name="PUT" access="public" output="false" hint="to update connect details in social login">

		<cfargument name="socialLoginType" 		type="string"  required="true"  hint="social login Type Name.">
		<cfargument name="socialLoginUserID" 	type="string"  required="true"  hint="socialLoginUserID of the user">
		<cfargument name="connectedStatus" 		type="numeric" required="true"  hint="connect status">
		<cfargument name="accessToken" 			type="string"  required="false" default="" hint="socialLogin accessToken of the user">

		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message']    = ''>
		<cfset result['error']      = true>

		<cftry>
			
			<cfswitch expression="#arguments.socialLoginType#">

				<cfcase value="facebook">

					<cfquery name="local.query" datasource="#variables.datasource#" result="facebook">

						UPDATE social_login_facebook 
							SET connectedStatus = <cfqueryparam value="#arguments.connectedStatus#" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="#arguments.accessToken#" cfsqltype="cf_sql_varchar">
								WHERE facebookUserID = <cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">
							
					</cfquery>

					<cfif facebook.recordCount EQ 0 >
						
						<cfset result['message']    = application.messages['mysocialNetwork_get_facebook_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysocialNetwork_put_facebook_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

				<cfcase value="twitter">

					<cfquery name="local.query" datasource="#variables.datasource#" result="twitter">

						UPDATE social_login_twitter
							SET connectedStatus = <cfqueryparam value="#arguments.connectedStatus#" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="#arguments.accessToken#" cfsqltype="cf_sql_varchar">
								WHERE twitterUserID =<cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">

					</cfquery>

					<cfif twitter.recordCount EQ 0 >
						
						<cfset result['message']    = application.messages['mysocialNetwork_get_twitter_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysocialNetwork_put_twitter_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

				<cfcase value="instagram">

					<cfquery name="local.query" datasource="#variables.datasource#" result="instagram">

						UPDATE social_login_instagram
							SET connectedStatus = <cfqueryparam value="#arguments.connectedStatus#" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="#arguments.accessToken#" cfsqltype="cf_sql_varchar">
								WHERE instagramUserID =<cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">

					</cfquery>

					<cfif instagram.recordCount EQ 0 >
						
						<cfset result['message']    = application.messages['mysocialNetwork_get_instagram_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysocialNetwork_put_instagram_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

				<cfcase value="google">

					<cfquery name="local.query" datasource="#variables.datasource#" result="google">

						UPDATE social_login_google
							SET connectedStatus = <cfqueryparam value="#arguments.connectedStatus#" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="#arguments.accessToken#" cfsqltype="cf_sql_varchar">
								WHERE id =<cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">

					</cfquery>

					<cfif google.recordCount EQ 0 >
						
						<cfset result['message']    = application.messages['mysocialNetwork_get_google_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysocialNetwork_put_google_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

				<cfcase value="pinterest">

					<cfquery name="local.query" datasource="#variables.datasource#" result="pinterest">

						UPDATE social_login_pinterest
							SET connectedStatus = <cfqueryparam value="#arguments.connectedStatus#" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="#arguments.accessToken#" cfsqltype="cf_sql_varchar">
								WHERE pinterestUserID =<cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">

					</cfquery>

					<cfif pinterest.recordCount EQ 0 >
						
						<cfset result['message']    = application.messages['mysocialNetwork_get_pinterest_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysocialNetwork_put_pinterest_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

			</cfswitch>

			<cfcatch>
			
				<cfset result.messages = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipe/{id}/PUT", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />
			
			</cfcatch>

		</cftry>

	</cffunction>

	<cffunction name="DELETE" access="public" output="false" hint="<code>DELETE</code> social Login record using socialTypes">

		<cfargument name="socialLoginType" 		type="string"  required="true" hint="social login Type Name.">
		<cfargument name="socialLoginUserID" 	type="string"  required="true" hint="socialLoginUserID of the user">		

		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message']    = ''>
		<cfset result['error']      = true>

		<cftry>
			
			<cfswitch expression="#arguments.socialLoginType#">

				<cfcase value="facebook">

					<cfquery name="local.query" datasource="#variables.datasource#" result="facebook">

						UPDATE social_login_facebook 
							SET connectedStatus = <cfqueryparam value="0" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="" cfsqltype="cf_sql_varchar" null="true">
								WHERE facebookUserID = <cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">
							
					</cfquery>

					<cfif facebook.recordCount EQ 0 >
						
						<cfset result['message']    = application.messages['mysocialNetwork_get_facebook_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysocialNetwork_delete_facebook_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

				<cfcase value="twitter">

					<cfquery name="local.query" datasource="#variables.datasource#" result="twitter">

						UPDATE social_login_twitter
							SET connectedStatus = <cfqueryparam value="0" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="" cfsqltype="cf_sql_varchar" null="true">
								WHERE twitterUserID =<cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">

					</cfquery>

					<cfif twitter.recordCount EQ 0 >
						
						<cfset result['message']    = application.messsages['mysocialNetwork_get_twitter_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysmysocialNetwork_delete_twitter_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

				<cfcase value="instagram">

					<cfquery name="local.query" datasource="#variables.datasource#" result="instagram">

						UPDATE social_login_instagram
							SET connectedStatus = <cfqueryparam value="0" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="" cfsqltype="cf_sql_varchar" null="true">
								WHERE instagramUserID =<cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">

					</cfquery>

					<cfif instagram.recordCount EQ 0 >
						
						<cfset result['message']    = application.messages['mysocialNetwork_get_instagram_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysocialNetwork_delete_instagram_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

				<cfcase value="google">

					<cfquery name="local.query" datasource="#variables.datasource#" result="google">

						UPDATE social_login_google
							SET connectedStatus = <cfqueryparam value="0" cfsqltype="cf_sql_bit">,
								access_token = <cfqueryparam value="" cfsqltype="cf_sql_varchar" null="true">
								WHERE id =<cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">

					</cfquery>

					<cfif google.recordCount EQ 0 >
						
						<cfset result['message']    = application.messages['mysocialNetwork_get_google_error']>
						<cfreturn representationOf(result).withStatus(404)>

					<cfelse>

						<cfset result['status']  	= true />
						<cfset result['message']    = application.messages['mysocialNetwork_delete_google_success']>
						<cfreturn representationOf(result).withStatus(200)>

					</cfif>

				</cfcase>

			</cfswitch>

			<cfcatch>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipe/{id}/DELETE", errorCatch = variables.cfcatch )>
				<cfset result.message =errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />
			
			</cfcatch>

		</cftry>
 		
	</cffunction>

</cfcomponent>