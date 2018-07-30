<cfcomponent extends="taffyAPI.base" taffy:uri="/user/{userID}" hint="User used to get, update and delete single user">
	
	<cffunction name="GET" access="public" hint="Return User Details DATA by searching the User's ID" returntype="struct" output="false">
		<cfargument name="userID"  		type="numeric" 	required="yes"	hint="Email address to search for">
		<cfargument name="cache"   	type="string" 	required="no"	hint="Query Cache Lenght" 	default="1" >
	 	
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />
		<cftry>
		
	        <cfquery datasource="#variables.datasource#" name="result.query">
	 				SELECT 
		 				u.userID,
		 				u.userName,
		 				u.userNameStatus,
		 				u.userEmail,
		 				u.userFirstName,
		 				u.userLastName,
		 				u.userDateLastLogin,
		 				CASE u.userGender	
							WHEN '0' THEN 'N/A'	
							WHEN 'M' THEN 'Male'
							WHEN 'F' THEN 'Female'
						END AS userGenderName,
		 				u.userAddressLine1,
		 				u.userAddressLine2,
		 				u.userAddressLine3,
		 				u.userCity,
		 				u.userStateID,
		 				u.userZip,
		 				u.userCountryID,
		 				u.userPhone1,
		 				u.userPhone1Ext,		 				
		 				u.userAbout,
		 				DATE_FORMAT(u.userDateBirth, '%d/%m/%Y') AS userDateBirth,		 				
		 				u.locationID,
		 				u.userDateConfirmed,
		 				u.influencerStatusID,
		 				vi.influencerStatusName,
		 				vi.influencerStatusDescription,
		 				u.isinfluencer,
		 				u.isValidBasicProfile,
		 				c.countryFullName,
           				vs.stateName,
           				u.isPublisher,
           				u.isallowpublisher,
           				u.roleID,
		 				CONCAT( i.imagePath, '/', i.imageName ) AS 'user_FullSize_Image',
						CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'user_Thumb_Image',
						CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'user_mini_Image',
						( SELECT COUNT(*) FROM users_follow WHERE entityTypeID = 4 and entityID = u.userID) AS 'userTotalFollowers'
	 				FROM users u
	 					LEFT JOIN images i ON i.entityID = u.userID AND i.entityTypeID = 4 AND i.active = 1
	 					LEFT JOIN val_countries c ON c.countryID = u.userCountryID
           				LEFT JOIN val_states vs ON vs.stateID = u.userStateID
           				LEFT JOIN val_influencerStatus vi ON vi.influencerStatusID = u.influencerStatusID
					WHERE u.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
					LIMIT 0,1
							
			</cfquery>

			<cfquery datasource="#variables.datasource#" name="local.userMetaDetails">
 				SELECT 
	 				meta_key,
	 				meta_value
 				FROM users_meta
				WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				 GROUP BY meta_key
			</cfquery>

			<cfset result['userMetaDetails'] = [] >
			<cfset local.user_meta 	 		 = {}>
			
			<cfloop query="local.userMetaDetails" >
				<cfset structInsert(local.user_meta,"#meta_key#","#meta_value#")>				
			</cfloop>

			<cfset arrayAppend(result.userMetaDetails, local.user_meta)>

			<cfset result['profileStrength'] = application.scoreObj.getInfluencerScore(userID = arguments.userID)>
			
			<!--- // Found? --->
			<cfif result.query.recordCount EQ 0>
				<cfset result.message = application.messages['user_get_found_error']>
				<cfreturn representationOf(result).withStatus(404) />
			</cfif>
		   
	 	  	<cfcatch>				
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /user/{userID}/GET", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		
	    </cftry>


	    <cfset result.status = true />
	    <cfset result.message = application.messages['user_get_found_success'] />

	  	<cfset logAction( actionID = 101, extra = "method: /user/{userID}/GET" )>

 		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<!--- Method :: PUT --->
	<cffunction name="PUT" access="public" output="false" returntype="struct" hint="user to update their user's details by <code> UPDATE </code> method">
		<cfargument name="userID" 				required="true"		type="numeric"	/>
		<cfargument name="userName" 			required="false"	type="string"	/>
		<cfargument name="userEmail" 			required="false"	type="string"	/>
		<cfargument name="userNameStatus" 		required="false"	type="numeric"	/>
		<cfargument name="userFirstName" 		required="false"	type="string"	/>
		<cfargument name="userLastName" 		required="false"	type="string"	/>
		<cfargument name="userPassword" 		required="false"	type="string"	/>		
		<cfargument name="userGender" 			required="false"	type="string"	/>
		<cfargument name="userAddressLine1" 	required="false"	type="string"	/>
		<cfargument name="userAddressLine2" 	required="false"	type="string"	/>
		<cfargument name="userAddressLine3" 	required="false"	type="string"	/>
		<cfargument name="userCity" 			required="false"	type="string"	/>
		<cfargument name="userStateID" 			required="false"	type="numeric"	/>
		<cfargument name="userZip" 				required="false"	type="string"	/>
		<cfargument name="userCountryID" 		required="false"	type="string"	/>
		<cfargument name="userPhone" 			required="false"	type="string"	/>
		<cfargument name="userPhone1Ext" 		required="false"	type="string"	/>
		<cfargument name="userPhone2" 			required="false"	type="string"	/>
		<cfargument name="userPhone2Ext" 		required="false"	type="string"	/>
		<cfargument name="userPhone3" 			required="false"	type="string"	/>
		<cfargument name="userPhone3Ext" 		required="false"	type="string"	/>		
		<cfargument name="userAbout" 			required="false"	type="string"	/>
		<cfargument name="userDateBirth" 		required="false"	type="any"		/>
		<cfargument name="userImageID"			required="false"	type="numeric"	/>
		<cfargument name="locationID" 			required="false"	type="numeric"	/>
		<cfargument name="timeZoneID" 			required="false"	type="numeric"	/>
		<cfargument name="active" 				required="false"	type="numeric"	/>
		<cfargument name="userPasswordReminder" required="false"	type="string"	/>
		<cfargument name="userPasswordQuestion" required="false"	type="string"	/>
		<cfargument name="roleID" 				required="false"	type="numeric"	/>
		<cfargument name="isAllowPublisher" 	required="false"	type="numeric"	/>
		<cfargument name="isPublisher" 			required="false"	type="numeric"	/>
		<cfargument name="publisherID" 			required="false"	type="numeric"	/>
		<cfargument name="userConfirmationCode" required="false"	type="string"	/>
		<cfargument name="userDateConfirmed" 	required="false"	type="any"		/>
		<cfargument name="isConfirmed" 			required="false"	type="numeric"	/>
		<cfargument name="isInfluencer" 		required="false"	type="numeric"	/>
		<cfargument name="influencerStatusID" 	required="false"	type="numeric"	/>
		<cfargument name="isUserEmailBounced" 	required="false"	type="numeric"	/>
		<cfargument name="isUserMarkedAsSpam" 	required="false"	type="numeric"	/>
		<cfargument name="referrerEnrolledDate" required="false"	type="any"		/>
		<cfargument name="referrerRejectedDate" required="false"	type="any"		/>
		<cfargument name="referrerAppliedDate" 	required="false"	type="any"		/>
		<cfargument name="referrerOptedOutDate" required="false"	type="any"		/>
		<cfargument name="referrerCommission" 	required="false"	type="numeric"	/>
		<cfargument name="isReferrerEnabled" 	required="false"	type="boolean" 	/>
		<cfargument name="referrerStatusID" 	required="false"	type="string"	/>

		<cftry>
			<cfset local.imageID = 0>

			<cfquery name="local.getUser" datasource="#variables.datasource#" result="getRecipeImageID">

				SELECT imageID
					FROM images
					WHERE entityID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
						AND entityTypeID = <cfqueryparam cfsqltype="cf_sql_integer" value="4">

			</cfquery>

			<cfset local.imageID = local.getUser.imageID>

			<cfif structKeyExists(arguments, "userImageID" ) AND len(arguments.userImageID ) AND arguments.userImageID NEQ 0>
				
				<cfset local.imageID = arguments.userImageID>


				<cfif local.getUser.imageID NEQ '' AND local.getUser.imageID NEQ 0 >

					<cfset local.imageResponse = httpRequest( methodName = 'DELETE', endPointOfURL = '/image/#local.getUser.ImageID#', timeout = 3000 ) />

				</cfif>

				<cfset local.attributes.entityID 	= arguments.userID />					
				<cfset local.attributes.entityTypeName = 'influencer' />					

				<cfset local.imageResponse = httpRequest( methodName = 'PUT', endPointOfURL = '/image/#arguments.userImageID#', timeout = 3000, parameters = local.attributes ) />

			</cfif>

			<cfset var local.qry = "" />
			<cfset var result = StructNew() />
			<cfset result['status']  	= false />
			<cfset result['message'] 	= "" />

			<cfquery name="local.qry" datasource="#variables.datasource#" result="isUpdated" >
				UPDATE users
				SET userID = userID
					<cfif structKeyExists(arguments, "userName" ) AND len(arguments.userName ) >
						,userName		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userName#" />		
					</cfif>
					<cfif structKeyExists(arguments, "userNameStatus" ) >
						,userNameStatus	 = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#arguments.userNameStatus#" />					
					</cfif>
					<cfif structKeyExists(arguments, "userEmail" ) AND len(arguments.userEmail ) >
						,userEmail		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userEmail#" />					
					</cfif>
					<cfif structKeyExists(arguments, "userFirstName" ) AND len(arguments.userFirstName ) >
						,userFirstName	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userFirstName#" />
					</cfif>
					<cfif structKeyExists(arguments, "userLastName" ) AND len(arguments.userLastName ) >
						,userLastName	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userLastName#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPassword" ) AND len(arguments.userPassword ) >
						,userPassword	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPassword#" />
					</cfif>

					<!---				
					,userDateRegistered	= <cfqueryparam cfsqltype="cf_sql_timestamp"	value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" />
					--->
								
					,userDateLastLogin	= <cfqueryparam cfsqltype="cf_sql_timestamp"	value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" />
					,userDateModified	= <cfqueryparam cfsqltype="cf_sql_timestamp"	value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" />

					<cfif structKeyExists(arguments, "userGender" ) AND len(arguments.userGender ) >
						,userGender		 = <cfqueryparam cfsqltype="cf_sql_char" value="#arguments.userGender#" />
					</cfif>
					<cfif structKeyExists(arguments, "userAddressLine1" )  >
						,userAddressLine1	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userAddressLine1#" />
					</cfif>
					<cfif structKeyExists(arguments, "userAddressLine2" )  >
						,userAddressLine2	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userAddressLine2#" />
					</cfif>
					<cfif structKeyExists(arguments, "userAddressLine3" ) >
						,userAddressLine3	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userAddressLine3#" />
					</cfif>
					<cfif structKeyExists(arguments, "userCity" ) >
						,userCity		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userCity#" />
					</cfif>
					<cfif structKeyExists(arguments, "userStateID" ) >
						,userStateID	 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userStateID#" />
					</cfif>
					<cfif structKeyExists(arguments, "userZip" )  >
						,userZip		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userZip#" />
					</cfif>
					<cfif structKeyExists(arguments, "userCountryID" ) AND len(arguments.userCountryID ) >
						,userCountryID	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userCountryID#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPhone" )  >
						,userPhone1		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPhone#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPhone1Ext" )  >
						,userPhone1Ext	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPhone1Ext#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPhone2" )  >
						,userPhone2		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPhone2#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPhone2Ext" )  >
						,userPhone2Ext	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPhone2Ext#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPhone3" )  >
						,userPhone3		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPhone3#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPhone3Ext" )  >
						,userPhone3Ext	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPhone3Ext#" />
					</cfif>					
					<cfif structKeyExists(arguments, "userAbout" ) >
						,userAbout		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userAbout#" />
					</cfif>
					<cfif structKeyExists(arguments, "userDateBirth" ) AND len(arguments.userDateBirth ) >
						,userDateBirth	 = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.userDateBirth#" />
					</cfif>
					
					<cfif structKeyExists(arguments, "locationID" ) >
						,locationID		 = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#arguments.locationID#" />
					</cfif>
					<cfif structKeyExists(arguments, "timeZoneID" ) >
						,timeZoneID		 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.timeZoneID#" />
					</cfif>
					<cfif structKeyExists(arguments, "active" ) >
						,active		 	= <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.active#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPasswordReminder" ) AND len(arguments.userPasswordReminder ) >
						,userPasswordReminder	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPasswordReminder#" />
					</cfif>
					<cfif structKeyExists(arguments, "userPasswordQuestion" ) AND len(arguments.userPasswordQuestion ) >
						,userPasswordQuestion	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userPasswordQuestion#" />
					</cfif>
					<cfif structKeyExists(arguments, "roleID" ) >
						,roleID		 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.roleID#" />
					</cfif>
					<cfif structKeyExists(arguments, "isAllowPublisher" ) >
						,isAllowPublisher	 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isAllowPublisher#" />
					</cfif>
					<cfif structKeyExists(arguments, "isPublisher" ) >
						,isPublisher		 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isPublisher#" />
					</cfif>
					<cfif structKeyExists(arguments, "publisherID" ) >
						,publisherID		 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.publisherID#" />
					</cfif>
					<cfif structKeyExists(arguments, "userConfirmationCode" ) AND len(arguments.userConfirmationCode ) >
						,userConfirmationCode	 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userConfirmationCode#" />
					</cfif>
					<cfif structKeyExists(arguments, "userDateConfirmed" ) AND len(arguments.userDateConfirmed ) >
						,userDateConfirmed		 = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.userDateConfirmed#" />
					</cfif>
					<cfif structKeyExists(arguments, "isConfirmed" ) >
						,isConfirmed		 	 = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#arguments.isConfirmed#" />
					</cfif>
					<cfif structKeyExists(arguments, "isInfluencer" ) >
						,isInfluencer		 	 = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#arguments.isInfluencer#" />
					</cfif>
					<cfif structKeyExists(arguments, "influencerStatusID" ) >
						,influencerStatusID		 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.influencerStatusID#" />
					</cfif>
					<cfif structKeyExists(arguments, "isUserEmailBounced" ) >
						,isUserEmailBounced		 = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#arguments.isUserEmailBounced#" />
					</cfif>
					<cfif structKeyExists(arguments, "isUserMarkedAsSpam" ) >
						,isUserMarkedAsSpam		 = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#arguments.isUserMarkedAsSpam#" />
					</cfif>
					<cfif structKeyExists(arguments, "referrerEnrolledDate" ) AND len(arguments.referrerEnrolledDate ) >
						,referrerEnrolledDate		 = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.referrerEnrolledDate#" />
					</cfif>
					<cfif structKeyExists(arguments, "referrerRejectedDate" ) AND len(arguments.referrerRejectedDate ) >
						,referrerRejectedDate		 = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.referrerRejectedDate#" />
					</cfif>
					<cfif structKeyExists(arguments, "referrerAppliedDate" ) AND len(arguments.referrerAppliedDate ) >
						,referrerAppliedDate		 = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.referrerAppliedDate#" />
					</cfif>
					<cfif structKeyExists(arguments, "referrerOptedOutDate" ) AND len(arguments.referrerOptedOutDate ) >
						,referrerOptedOutDate		 = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.referrerOptedOutDate#" />
					</cfif>
					<cfif structKeyExists(arguments, "referrerCommission" ) >
						,referrerCommission		 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.referrerCommission#" />
					</cfif>
					<cfif structKeyExists(arguments, "isReferrerEnabled" ) AND len(arguments.isReferrerEnabled ) >
						,isReferrerEnabled		 = <cfqueryparam cfsqltype="cf_sql_bit" value="#arguments.isReferrerEnabled#" />
					</cfif>
					<cfif structKeyExists(arguments, "referrerStatusID" ) AND len(arguments.referrerStatusID ) >
						,referrerStatusID		 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.referrerStatusID#" />                                          
					</cfif>					

					WHERE userID 	= <cfqueryparam  cfsqltype="cf_sql_numeric" value="#arguments.userID#" />
			</cfquery>		

			<cfset statusCode = ( isUpdated.recordCount GT 0 ) ? 200 : 404 >

			<cfif statusCode = 200>

				<cfset local.userDetails = httpRequest( methodName = 'GET', endPointOfURL = '/user/#arguments.userID#', timeout = 3000) />
				<cfset result.userUpdateDetails = deserializeJson(local.userDetails.filecontent)>

				<cfset local.userDetails = result.userUpdateDetails.dataset[1] />

				<!--- Checking the user data fields and updating the isValidBasicProfile details --->
				<!--- 
						Note: we can't add it in the above query because we are checking the image
							to make the user profile as a valid one.
				--->
				<cfquery name="local.userDetails" datasource="#variables.datasource#" result="isUserValidBasicProfile" >
					UPDATE users
						SET
						<cfif len( trim( local.userDetails.user_fullsize_image) ) AND ( structKeyExists(local.userDetails, "userFirstName" ) AND len(local.userDetails.userFirstName ) ) AND ( structKeyExists(local.userDetails, "userLastName" ) AND len(local.userDetails.userLastName ) ) AND ( structKeyExists(local.userDetails, "userCountryID" ) AND len(local.userDetails.userCountryID ) AND ( local.userDetails.userCountryID NEQ 1 OR local.userDetails.userCountryID NEQ 0 ) ) >
							isValidBasicProfile = <cfqueryparam value="1" cfsqltype="cf_sql_integer">
						<cfelse>
							isValidBasicProfile = <cfqueryparam value="0" cfsqltype="cf_sql_integer">
						</cfif>
						WHERE userID 	= <cfqueryparam  cfsqltype="cf_sql_numeric" value="#arguments.userID#" />
				</cfquery>

		  		<cfset logAction( actionID = 102, extra = "method: /user/{userID}/PUT" )>
				<cfreturn representationOf(result).withStatus(200) />

			<cfelse>

				<cfset logAction( actionID = 102, extra = "method: /user/{userID}/PUT" )>
				<cfreturn noData().withStatus(404) />
			</cfif>

			<cfcatch>		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /user/{userID}/PUT", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage(message= 'user_put_update_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>
		
	</cffunction>


	<cffunction name="DELETE" access="public" output="false" hint="user can delete their user record using <code> DELETE </code> method.">
		<cfargument name="userID" type="numeric" required="true" />

		<cfset result['messgae'] = "">
		<cfset result['status']	 = "">
		<cfset result['error']   = "">

		<cftry>
			<cfset var local.qry = "" />
			
			<cfquery name="local.qry" datasource="#variables.datasource#" result="isDeleted">
				DELETE FROM users WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#" />
				LIMIT 1
			</cfquery>

			<cfcatch>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /user/{userID}/DELETE", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		</cftry>	

		<cfset statusCode = ( isDeleted.recordCount GT 0 ) ? 200 : 404 >

		<cfset result.status = true />
		<cfset result.message =statusCode EQ 200? application.messages['user_delete_remove_success'] : application.messages['user_delete_remove_error']  >

	  	<cfset logAction( actionID = 114, extra = "method: /user/{userID}/DELETE" )>

		<cfreturn representationOf(result).withStatus(statusCode) />
	</cffunction>

</cfcomponent>