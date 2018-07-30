<cfcomponent extends="taffyAPI.base" taffy:uri="/socialPostDetails/" hint="Getting the socialPost details">

	<cffunction name="GET" access="public" output="true" hint="Used to get the socialPost details.">
		<cfargument name="functionName" required="true" type="string" hint="function name is related to the social network.">
		<cfargument name="attributes"   required="true" type="string" hint="">

		<cfset structAppend( arguments, deserializeJson( arguments.attributes ) )>

		<cfset result = structNew() />
        <cfset result['status'] = false />
        <cfset result['errors'] = "" >
		<cfset result['errorsforlog'] = "" >
		<cfset result['message'] = "">

        <cfswitch expression="#arguments.functionName#">

        	<cfcase value="GetfbPostDetails">

        		<cfscript>

        			param name="arguments.postID"			type="string" default="";				
					param name="arguments.accessToken" 		type="string" default="";

					if ( arguments.postID EQ '' OR len(arguments.postID) EQ 0 ) {
						result['errors'] = listAppend(result['errors'], "postID");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "postID: #arguments.postID# is required.");
					}

					if ( arguments.accessToken EQ '' OR len(arguments.accessToken) EQ 0 ) {
						result['errors'] = listAppend(result['errors'], "accessToken");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "accessToken: #arguments.accessToken# is required.");
					}

					if ( ListLen(result['errors']) GT 0 ) {

						result['error'] = true; 
						result.message = application.messages['sociapostdetails_get_fbpostdetails_error'];
						// Log Invalid Registration Input
						local.logAction = logAction( actionID = 55, extra = result['errorsforlog'] );
						
						return representationOf(result).withStatus(406);

					} else {

						http = new http();

						http.settimeout(3000);

						http.seturl( 'https://graph.facebook.com/#arguments.postID#/?fields=shares,likes.summary(true),comments.summary(true),message,full_picture' );
						http.setMethod( 'GET' );

						http.addParam(type="url", name="access_token", value="#arguments.accessToken#");					

						returnData = http.send().getPrefix();
						
						if( returnData.status_code EQ 200 ){
							
							result.fbPostDetails = deserializeJson(returnData.filecontent);

						}else{
							
							errorDetails = deserializeJson(returnData.filecontent);							
							result['errors'] = errorDetails.error.type;
							result['errorsforlog'] = "#errorDetails.error.type# : #errorDetails.error.message#";
							result['message'] = errorDetails.error.message;

							logAction( actionID = 1009, extra = "method: /socialPostDetails/GET function: GetfbPostDetails" );
							return representationOf(result).withStatus(400);

						}

						result['status'] = true;
						result.message = application.messages['sociapostdetails_get_fbpostdetails_success'];
						logAction( actionID = 1007, extra = "method: /socialPostDetails/GET function: GetfbPostDetails" );
						return representationOf(result).withStatus(200);
					}
        		
        		</cfscript>
        		
        	</cfcase>
        	
    		<cfcase value="GetTweetDetails">

    			<cfscript>
    				
    				param name="arguments.id" type="string" default=""; 	
    				
    				if ( arguments.id EQ '' OR len(arguments.id) EQ 0 ) {

						result['errors'] = listAppend(result['errors'], "id");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "id is required.");

					}

					if ( ListLen(result['errors']) GT 0 ) {

						result['error'] = true; 
				
						local.logAction = logAction( actionID = 55, extra = result['errorsforlog'] );
						result.message = application.messages['sociapostdetails_get_twitterpostdetails_error'];
						return representationOf(result).withStatus(406);

					} else {

    					result.query = queryNew("name,screenname,tweettext,retweetscount,favoritecount,tweetimage", "varchar,varchar,varchar,varchar,varchar,varchar");

        				tweetdetails =application.objMonkehTweet.getStatusByID(arguments.id);

        				if (structKeyExists(tweetdetails,'errors')){

        					result['errors']  = listAppend(result['errors'], "id");
        					result['message'] = 'invalid id:#arguments.id#';
        					return representationOf(result).withStatus(406);

        				}
        				queryAddRow(result.query);
        				querySetCell(result.query, "name", tweetdetails.user.name);
        				querySetCell(result.query, "screenname", tweetdetails.user.screen_name);
        				querySetCell(result.query, "tweettext",  tweetdetails.text);
        				querySetCell(result.query, "retweetscount", tweetdetails.retweet_count);
        				querySetCell(result.query, "favoritecount", tweetdetails.favorite_count);
        				
        				if(structKeyExists(tweetdetails,'extended_entities')){

        					querySetCell(result.query,'tweetimage', tweetdetails.extended_entities.media[1].media_url_https);
        				}

    				}
					result.message = application.messages['sociapostdetails_get_twitterpostdetails_success'];

        			return representationOf(result).withStatus(200);
    				
  				</cfscript>

    		</cfcase>

        	<cfcase value="GetInstagramPostDetails">

        		<cfscript>

        			param name="arguments.shortCode" default="";
        			param name="arguments.accessToken" default="";
        			
        			if ( arguments.shortCode EQ '' OR len(arguments.shortCode) EQ 0 ) {

						result['errors'] = listAppend(result['errors'], "shortCode");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "shortCode: #arguments.shortCode# is required.");

					}

					if ( arguments.accessToken EQ '' OR len(arguments.accessToken) EQ 0 ) {

						result['errors'] = listAppend(result['errors'], "accessToken");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "accessToken: #arguments.accessToken# is required.");

					}

					if ( ListLen(result['errors']) GT 0 ) {

						result['error'] = true; 
				
						// Log Invalid Registration Input
						local.logAction = logAction( actionID = 55, extra = result['errorsforlog'] );
						result.message = application.messages['sociapostdetails_get_instagrampostdetails_error'];
						
						return representationOf(result).withStatus(406);

					} else {

						http = new http();

						http.settimeout(3000);

						http.seturl( 'https://api.instagram.com/v1/media/shortcode/#arguments.shortCode#?' );
						http.setMethod( 'GET' );

						http.addParam(type="url", name="access_token", value="#arguments.accessToken#");					

						returnData = http.send().getPrefix();
						
						if( returnData.status_code EQ 200 ){
							
							result.instagramPostDetails = deserializeJson(returnData.filecontent);

						} else {

							errorDetails = deserializeJson(returnData.filecontent);							
							result['errors'] = errorDetails.error.type;
							result['errorsforlog'] = "#errorDetails.error.type# : #errorDetails.error.message#";
							result['message'] = errorDetails.error.message;

							logAction( actionID = 1009, extra = "method: /socialPostDetails/GET function: GetInstagramPostDetails" );

							return representationOf(result).withStatus(400);

						}

						result['status'] = true;
						logAction( actionID = 1007, extra = "method: /socialPostDetails/GET function: GetInstagramPostDetails" );
						result.message = application.messages['sociapostdetails_get_instagrampostdetails_success'];

						return representationOf(result).withStatus(200);

					}

        		</cfscript>
        		
        	</cfcase>

        </cfswitch>

	</cffunction>

</cfcomponent>