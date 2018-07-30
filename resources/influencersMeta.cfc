<cfcomponent extends="taffyAPI.base" taffy:uri="/influencersMeta/" hint="influencers Meta Data. ie. AdUnits, etc.">

	<cffunction name="GET" access="public" returntype="struct" output="true" hint="Return influencers Meta DATA" auth="true">
		<cfargument name="userID"  		type="numeric"  required="true" hint="User ID">
		<cfargument name="auth_token"   type="string"   required="true" hint="User authorization token (auth_token).">		
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['message'] = "" />
		<cfset result['status'] = false />

		<cftry>

			<!--- START:: availability functionality  --->

			<!--- SELECT:: influencers meta value from influencers_meta --->
			<cfset availabilityColumnNames = 'status_visibility,status_availability,status_location_city,status_location_state,status_location_country'>
			<cfset local.queryAvailability = application.influencerMetaObj.getInfluencerMeta( meta_key = availabilityColumnNames, userID = arguments.userID ) >			

			<!--- IF EMPTY:: if availabilty data are empty--->
			<cfif local.queryAvailability.recordCount EQ 0>
				
				<cfset result['DATASET']['availability'] = influencerEmptyMetaDetails(columns = availabilityColumnNames)>

			<cfelse>

				<!--- conversion:: convert the query into structure format --->
				<cfset result['DATASET']['availability'] = queryToStruct(query=local.queryAvailability , keyCol = 'meta_key' , valueCol = 'meta_value' )>

			</cfif>
			<!--- END:: availability functionality  --->

			
			<!--- START:: basics functionality  --->
			<!--- SELECT:: influencers meta value from influencers_meta --->
			<cfset basicsColumnNames = 'title,about,bio,experience,media,award'>
			<cfset local.basicsQuery = application.influencerMetaObj.getInfluencerMeta( meta_key = basicsColumnNames, userID = arguments.userID ) >

			<!--- IF EMPTY:: if basics data are empty--->
			<cfif local.basicsQuery.recordCount EQ 0>

				<cfset result['DATASET']['basics'] = influencerEmptyMetaDetails(columns = basicsColumnNames)>

			<cfelse>

				<!--- conversion:: convert the query into structure format --->
				<cfset result['DATASET']['basics'] = queryToStruct(query=local.basicsQuery , keyCol = 'meta_key' , valueCol = 'meta_value' )>

			</cfif>			

			<cfif structKeyExists(result['DATASET']['basics'], "media") AND result.dataset.basics.media NEQ 0 >
				<cfset result['DATASET']['basics']['media'] = listToArray(result['DATASET']['basics']['media'], chr(7)) >
			</cfif>

			<cfif structKeyExists(result['DATASET']['basics'], "award") AND result.dataset.basics.award NEQ 0 >
				<cfset result['DATASET']['basics']['award'] = listToArray(result['DATASET']['basics']['award'], chr(7)) >
			</cfif>			

			<!--- START:: get influencers skills data from tags  --->
			<cfset local.attributes = {} >
			<cfset local.attributes.entityID 	 = arguments.userID>
			<cfset local.attributes.entityTypeID = 30>
			
			<cfset getTagResponse = httpRequest( methodName = 'GET', endPointOfURL = '/tags', timeout = 3000, parameters = local.attributes ) >

			<cfset local['skill'] =arrayNew()>

			<!--- START::if skills data available --->
			<cfif getTagResponse.status_code EQ 200>

				<cfset local.skills = deserializeJSON(getTagResponse.filecontent).dataset>

				<cfloop array="#local.skills#" index="element">
					<cfset arrayAppend(local.skill, structFind(element, "tagName"))>
				</cfloop>

			</cfif>

			<cfset structInsert(result['DATASET']['basics'], "skills", local.skill)>

			<!--- END:: if skills data available --->
			<!--- END:: get influencers skills data from tags  --->
			<!--- END:: basics functionality  --->


			<!--- START:: activity functionality  --->
			<!--- Getting influencers_meta table data --->
			<cfset activityColumnNames = 'freq_post,freq_review'>
			<cfset local.activityQuery = application.influencerMetaObj.getInfluencerMeta( meta_key = activityColumnNames, userID = arguments.userID ) >

			<cfif local.activityQuery.recordCount EQ 0 >
				
				<cfset result['DATASET']['activity'] = influencerEmptyMetaDetails(columns = activityColumnNames)>

			<cfelse>

				<cfset result['DATASET']['activity'] = queryToStruct(query=local.activityQuery , keyCol = 'meta_key' , valueCol = 'meta_value' )>

			</cfif>

			<!--- START:: get influencers brandsLove data from tags  --->
			<cfset structClear(local.attributes) >
			<cfset local.attributes.entityID 	 = arguments.userID>
			<cfset local.attributes.entityTypeID = 31>
			
			<cfset getTagResponse = httpRequest( methodName = 'GET', endPointOfURL = '/tags', timeout = 3000, parameters = local.attributes ) >

			<cfset local['brandLove'] =arrayNew()>

			<!--- START::if brandsLove data available --->
			<cfif getTagResponse.status_code EQ 200>

				<cfset brandsLove = deserializeJSON(getTagResponse.filecontent).dataset>

				<cfloop array="#brandsLove#" index="element">
					<cfset arrayAppend(local.brandLove, structFind(element, "tagName"))>
				</cfloop>

			</cfif>

			<cfset structInsert(result['DATASET']['activity'], "brandsLove", local.brandLove)>
			<!--- END::if brandsLove data available --->

			<!--- END:: get influencers brandsLove data from tags  --->

			<cfset structInsert( result['DATASET']['activity'], "programsName",   getOptions( userID = arguments.userID, optionTypeID = 1  ) ) >
			<cfset structInsert( result['DATASET']['activity'], "promotionsName", getOptions( userID = arguments.userID, optionTypeID = 2  ) ) >
			<!--- END:: activity functionality  --->

			<!--- START :: platforms functionality  --->
			<!--- SELECT:: influencers meta value from influencers_meta --->
			<cfset platformsColumnNames = 'freq_post_social,freq_post_video'>
			<cfset local.platformsQuery = application.influencerMetaObj.getInfluencerMeta( meta_key = platformsColumnNames, userID = arguments.userID ) >			

			<!--- IF EMPTY:: if platforms data are empty--->
			<cfif local.platformsQuery.recordCount EQ 0>
				
				<cfset result['DATASET']['platforms'] = influencerEmptyMetaDetails(columns = platformsColumnNames)>

			<cfelse>

				<!--- conversion:: convert the query into structure format --->
				<cfset result['DATASET']['platforms'] = queryToStruct(query=local.platformsQuery , keyCol = 'meta_key' , valueCol = 'meta_value' )>

			</cfif>

			<!--- START:: GET influencers socialMedia and websites names  --->
			<cfset local.socialMediaName = 	getOptions( userID = arguments.userID, optionTypeID = 3)>
			<cfset local.websitesName 	 = 	getOptions( userID = arguments.userID, optionTypeID = 4)>

			<cfset structInsert(result['DATASET']['platforms'], "socialMediaName", local.socialMediaName )>
			<cfset structInsert(result['DATASET']['platforms'], "websitesName", local.websitesName )>
			<!--- END:: platforms functionality  --->

			<!--- START:: foodPreferences functionality  --->
			<!--- Getting influencers_meta table data --->
			<cfset foodPreferencesColumnNames = 'freq_cook,freq_tea,freq_soda,freq_alcohol,freq_coffee,rate_eco,interest_organic'>
			<cfset local.foodPreferencesQuery = application.influencerMetaObj.getInfluencerMeta( meta_key = foodPreferencesColumnNames, userID = arguments.userID ) >						

			<cfif local.foodPreferencesQuery.recordCount EQ 0 >

				<cfset result['DATASET']['foodPreferences'] = influencerEmptyMetaDetails(columns = foodPreferencesColumnNames)>

			<cfelse>

				<cfset result['DATASET']['foodPreferences'] = queryToStruct(query=local.foodPreferencesQuery , keyCol = 'meta_key' , valueCol = 'meta_value' )>

			</cfif>

			<!--- START:: get influencer_meta value for meat_dairy  --->
			<cfquery name="local.influencersChannel" datasource="#variables.datasource#">

				SELECT optionName 
					FROM val_influencer_options 
					WHERE optionID = ( 
						SELECT meta_value 
							FROM influencers_meta 
								WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
								AND meta_key = <cfqueryparam value="meat_dairy" cfsqltype="cf_sql_varchar">
						 )

			</cfquery>

			<cfif local.influencersChannel.recordCount >
				
				<cfset result['DATASET']['foodPreferences']['meat_dairy'] = local.influencersChannel.optionName >

			</cfif>
			<!--- END:: get influencer_meta value for meat_dairy  --->

			<!--- START:: get influencers food_love data from tags  --->
			<cfset structClear(local.attributes) >
			<cfset local.attributes.entityID 	 = arguments.userID >
			<cfset local.attributes.entityTypeID = 32 >
			
			<cfset getTagResponse = httpRequest( methodName = 'GET', endPointOfURL = '/tags', timeout = 3000, parameters = local.attributes ) >

			<cfset local['foodLove'] =arrayNew()>

			<!--- START::if food_love data available --->
			<cfif getTagResponse.status_code EQ 200>

				<cfset food_love = deserializeJSON(getTagResponse.filecontent).dataset>

				<cfloop array="#food_love#" index="element">
					<cfset arrayAppend(local.foodLove, structFind(element, "tagName"))>
				</cfloop>

			</cfif>

			<cfset structInsert(result['DATASET']['foodPreferences'], "food_love", local.foodLove)>
			<!--- END::if food_love data available --->

			<!--- START:: get influencers food_avoid data from tags  --->
			<cfset structClear(local.attributes) >
			<cfset local.attributes.entityID 	 = arguments.userID >
			<cfset local.attributes.entityTypeID = 33 >
			
			<cfset getTagResponse = httpRequest( methodName = 'GET', endPointOfURL = '/tags', timeout = 3000, parameters = local.attributes ) >

			<cfset local['foodAvoid'] =arrayNew()>

			<!--- START::if food_avoid data available --->
			<cfif getTagResponse.status_code EQ 200>

				<cfset food_avoid = deserializeJSON(getTagResponse.filecontent).dataset>

				<cfloop array="#food_avoid#" index="element">
					<cfset arrayAppend(local.foodAvoid, structFind(element, "tagName"))>						
				</cfloop>

			</cfif>
			<cfset structInsert(result['DATASET']['foodPreferences'], "food_avoid", local.foodAvoid)>
			<!--- END::if food_avoid data available --->

			<cfset structInsert( result['DATASET']['foodPreferences'], "groceriesName", 	getOptions( userID = arguments.userID, optionTypeID = 6  ) ) >
			
			<!--- START:: getting influencers_allergy records --->
			<cfquery name="local.influencersAllergy" datasource="#variables.datasource#">

				SELECT va.allergyName 
					FROM influencers_allergy AS i 
					INNER JOIN val_recipe_allergy AS va 
					ON i.allergyID = va.allergyID 
					WHERE userID =	<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric">

			</cfquery>
			
			<cfset local.influencers_allergy = arrayNew() >

			<cfloop query="local.influencersAllergy">

				<cfset arrayAppend(local.influencers_allergy, allergyName)>

			</cfloop>

			<cfset structInsert(result['DATASET']['foodPreferences'], "influencers_allergy", local.influencers_allergy)>
			<!--- END:: getting influencers_allergy records --->

			<!--- START:: getting influencers_channel records --->
			<cfquery name="local.influencersChannel" datasource="#variables.datasource#">

				SELECT vc.channelName 
					FROM influencers_channel AS i 
					INNER JOIN val_recipe_channel AS vc
					ON i.channelID = vc.channelID 
					WHERE userID = 	<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric">

			</cfquery>				
			
			<cfset local.influencers_channel = arrayNew() >				

			<cfloop query="local.influencersChannel">

				<cfset arrayAppend(local.influencers_channel, channelName)>

			</cfloop>

			<cfset structInsert(result['DATASET']['foodPreferences'], "influencers_channel", local.influencers_channel)>
			<!--- END:: getting influencers_channel records --->

			<!--- START:: getting influencers_cuisine records --->
			<cfquery name="local.influencersCuisine" datasource="#variables.datasource#">

				SELECT vc.cuisineName 
					FROM influencers_cuisine AS i 
					INNER JOIN val_recipe_cuisine AS vc
					ON i.cuisineID = vc.cuisineID 
					WHERE userID = 	<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric">

			</cfquery>				
			
			<cfset local.influencers_cuisine = arrayNew() >

			<cfloop query="local.influencersCuisine">

				<cfset arrayAppend(local.influencers_cuisine, cuisineName)>

			</cfloop>

			<cfset structInsert(result['DATASET']['foodPreferences'], "influencers_cuisine", local.influencers_cuisine)>
			<!--- END:: getting influencers_cuisine records --->

			<!--- START:: getting influencers_diet records --->
			<cfquery name="local.influencersDiet" datasource="#variables.datasource#">

				SELECT vd.dietName 
					FROM influencers_diet AS i 
					INNER JOIN val_recipe_diet AS vd
					ON i.dietID = vd.dietID
					WHERE userID = 	<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric">

			</cfquery>				
			
			<cfset local.influencers_diet 	 = arrayNew() >

			<cfloop query="local.influencersDiet">

				<cfset arrayAppend(local.influencers_diet, dietName)>

			</cfloop>

			<cfset structInsert(result['DATASET']['foodPreferences'], "influencers_diet", local.influencers_diet)>
			<!--- END:: getting influencers_diet records --->
			<!--- END:: foodPreferences functionality  --->

			<!--- START:: demographics functionality   --->
		 	<!--- SELECT:: influencers meta value from influencers_meta --->
			<cfset demographicsColumnNames = 'age,income,children,education,ethnicity'>			
			<cfset local.demographicsQuery = application.influencerMetaObj.getInfluencerMeta( meta_key = demographicsColumnNames, userID = arguments.userID ) >
			
			<cfif local.demographicsQuery.recordCount EQ 0>

				<cfset result['DATASET']['demographics'] = influencerEmptyMetaDetails(columns = demographicsColumnNames)>

			<cfelse>

				<cfset local['metaData'] = queryToStruct( query = local.demographicsQuery , keyCol = 'meta_key' , valueCol = 'meta_value' )>

				<cfquery name="local.age" datasource="#variables.datasource#">

					SELECT ageName FROM val_demographics_age 
						WHERE ageID = <cfqueryparam value="#local.metaData.age#" cfsqltype="cf_sql_varchar">
						
				</cfquery>

				<cfquery name="local.income" datasource="#variables.datasource#">

					SELECT incomeName FROM val_demographics_income 
						WHERE incomeID = <cfqueryparam value="#local.metaData.income#" cfsqltype="cf_sql_varchar">
						
				</cfquery>

				<cfquery name="local.children" datasource="#variables.datasource#">

					SELECT childrenName FROM val_demographics_children 
						WHERE childrenID = <cfqueryparam value="#local.metaData.children#" cfsqltype="cf_sql_varchar">
						
				</cfquery>

				<cfquery name="local.education" datasource="#variables.datasource#">

					SELECT educationName FROM val_demographics_education 
						WHERE educationID = <cfqueryparam value="#local.metaData.education#" cfsqltype="cf_sql_varchar">
						
				</cfquery>

				<cfquery name="local.ethnicity" datasource="#variables.datasource#">

					SELECT ethnicityName FROM val_demographics_ethnicity 
						WHERE ethnicityID = <cfqueryparam value="#local.metaData.ethnicity#" cfsqltype="cf_sql_varchar">
						
				</cfquery>

				<cfset result['DATASET']['demographics'] = structNew()>

				<cfset structInsert(result['DATASET']['demographics'], "age", local.age.recordCount?local.age.ageName:'')>
				<cfset structInsert(result['DATASET']['demographics'], "income", local.income.recordCount?local.income.incomeName:'')>
				<cfset structInsert(result['DATASET']['demographics'], "children", local.children.recordCount?local.children.childrenName:'')>
				<cfset structInsert(result['DATASET']['demographics'], "education", local.education.recordCount?local.education.educationName:'')>
				<cfset structInsert(result['DATASET']['demographics'], "ethnicity", local.ethnicity.recordCount?local.ethnicity.ethnicityName:'')>
				

			</cfif>
			<!--- END:: demographics functionality   --->			

			<cfset result['status'] 	= true >
			<cfset result['message'] 	= application.messages['influencersMeta_get_found_success']>

			<cfreturn representationOf(result).withStatus(200)>

			<cfcatch>

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /influencersMeta/GET", errorCatch = variables.cfcatch  )>
				
				<cfset result['message'] 	= errorMessage( message = 'influencersMeta_get_found_error', error = variables.cfcatch)>

				<cfreturn representationOf(result.message).withStatus(500) />
				
			</cfcatch>
			
		</cftry>
		

	</cffunction>


	<cffunction name="POST" access="public" returntype="Struct" output="true" hint="insert the meta data under the user." auth="true" >

		<cfargument name="userID"		type="numeric"required="true">
		<cfargument name="auth_token"	type="string" required="true">
		<cfargument name="attributes"   type="string" required="true" hint="User's Form data submitted from front-end.">
		<cfargument name="functionName"	type="string" required="true" hint="function name oof the POST method">

		<cfset structAppend( arguments, deserializeJson( arguments.attributes ) )>

		<cfset result = structNew() >
		<cfset result['error'] 		= true >
		<cfset result['status'] 	= false>
		<cfset result['message'] 	= "">

		<cftry>
	
			<cfswitch expression="#arguments.functionName#">

				<!--- START:: Availability tab functionality --->
				<cfcase value="availability">

					<cfparam name="arguments.status_visibility" 		type="string"  default="0">
					<cfparam name="arguments.status_availability" 		type="string"  default="0">
					<cfparam name="arguments.status_location_city" 		type="string"  default="0">
					<cfparam name="arguments.status_location_state" 	type="string"  default="0">
					<cfparam name="arguments.status_location_country" 	type="string"  default="0">
					<cfparam name="arguments.score" 					type="numeric" default="0">

					<!--- START ::check whether the meta data is exist or not --->
					<cfset metaColumns = 'status_visibility,status_availability,status_location_city,status_location_state,status_location_country,score'>
					<cfset local.isExist = application.influencerMetaObj.getInfluencerMeta( meta_key = metaColumns, userID = arguments.userID )>

					<!--- If exist? deleting the data. --->
					<cfif local.isExist.recordCount GT 0>

						<cfset application.influencerMetaObj.deleteInfluencerMeta( metaColumns = metaColumns ,userID = arguments.userID)>

					</cfif>

					<!--- END ::check whether the meta data is exist or not --->

					<!--- START:: insert meta data --->

					<cfset local.attributes['status_visibility'] 		= arguments.status_visibility>
					<cfset local.attributes['status_availability'] 		= arguments.status_availability>
					<cfset local.attributes['status_location_city'] 	= arguments.status_location_city>
					<cfset local.attributes['status_location_state'] 	= arguments.status_location_state>
					<cfset local.attributes['status_location_country'] 	= arguments.status_location_country>

					<cfloop collection="#local.attributes#" item="key">
						
						<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = key, meta_value = structFind(local.attributes, key), userID = arguments.userID )>

					</cfloop>

					<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = 'score', meta_value = application.scoreObj.getInfluencerScore( userID = arguments.userID ), userID = arguments.userID )>

					<!--- END :: insert meta data --->

					<cfset result['error'] 		= false >
					<cfset result['status'] 	= true >
					<cfset result['message'] 	= application.messages['influencersMeta_post_availabilty_success']>

					<cfreturn representationOf(result).withStatus(200)>

				</cfcase>
				<!--- END:: Availability tab functionality --->

				<!--- START:: Basics tab functionality --->
				<cfcase value="basics">

					<cfparam name="arguments.title" 	 type="string"  default="">
					<cfparam name="arguments.about" 	 type="string"  default="">
					<cfparam name="arguments.bio" 		 type="string"  default="">
					<cfparam name="arguments.experience" type="string"  default="">
					<cfparam name="arguments.score" 	 type="numeric" default="0">
					<cfparam name="arguments.media" 	 type="array"   default="#arraynew()#">
					<cfparam name="arguments.award" 	 type="array"   default="#arraynew()#">
					<cfparam name="arguments.skills" 	 type="array"   default="#arraynew()#">

					<!--- START ::check whether the meta data is exist or not --->
					<cfset metaColumns = 'title,about,bio,experience,media,award,score'>
					<cfset local.basics = application.influencerMetaObj.getInfluencerMeta( meta_key = metaColumns, userID = arguments.userID )>
					
					<!--- If exist? Deleting the data. --->
					<cfif local.basics.recordCount NEQ 0 >

						<cfset application.influencerMetaObj.deleteInfluencerMeta( metaColumns = metaColumns ,userID = arguments.userID)>

						<cfset deleteTags( userID = arguments.userID , entityID = arguments.userID, entityTypeID = 30)>

					</cfif>
					<!--- END ::check whether the meta data is exist or not --->

					<!--- START:: insert meta data --->
					<cfset local.attributes = {} >

					<cfset local.attributes['title'] 	  = arguments.title>
					<cfset local.attributes['about'] 	  = arguments.about>
					<cfset local.attributes['bio'] 		  = arguments.bio>
					<cfset local.attributes['media'] 	  = arrayToList( arguments.media ,chr(7) )>
					<cfset local.attributes['award'] 	  = arrayToList( arguments.award ,chr(7) )>
					<cfset local.attributes['experience'] = arguments.experience>

					<cfloop collection="#local.attributes#" item="key">
						
						<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = key, meta_value = structFind(local.attributes, key), userID = arguments.userID )>

					</cfloop>
					<!--- END :: insert meta data --->
						
					<!--- START:: calling tags post to insert the tag --->
					<cfif structKeyExists(arguments,'skills') AND arrayLen(arguments.skills) GT 0>

						<cfloop array="#arguments.skills#" index="local.skill" >

							<cfset structClear(local.attributes) >

							<cfset local.attributes['tags'] 		= local.skill >
							<cfset local.attributes['userID'] 		= arguments.userID >
							<cfset local.attributes['auth_token'] 	= arguments.auth_token >
							<cfset local.attributes['entityID'] 	= arguments.userID >
							<cfset local.attributes['entityTypeID'] = 30 >

							<cfset getTagResponse = httpRequest( methodName = 'POST', endPointOfURL = '/tags', timeout = 3000, parameters = local.attributes ) >
							
						</cfloop>

					</cfif>
					<!--- END:: calling tags post to insert the tag --->

					<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = 'score', meta_value = application.scoreObj.getInfluencerScore( userID = arguments.userID ), userID = arguments.userID )>

					<cfset result['error'] 		= false >
					<cfset result['status'] 	= true >
					<cfset result['message'] 	= application.messages['influencersMeta_post_basics_success']>

					<cfreturn representationOf(result).withStatus(200)>
						
				</cfcase>
				<!--- END:: Basics tab functionality --->

				<!--- START:: Activity tab functionality --->
				<cfcase value="activity">

					<cfparam name="arguments.freq_post" 		type="string" 	default="0">
					<cfparam name="arguments.freq_review" 		type="string" 	default="0">
					<cfparam name="arguments.score" 	 		type="numeric"  default="0">
					<cfparam name="arguments.programsName" 		type="array" 	default="#arrayNew()#">
					<cfparam name="arguments.promotionsName"    type="array" 	default="#arrayNew()#">
					<cfparam name="arguments.brandsLove"		type="array" 	default="#arrayNew()#">

					<!--- START ::check whether the meta data is exist or not --->
					<cfset metaColumns = 'freq_post,freq_review,score'>
					<cfset local.isExist = application.influencerMetaObj.getInfluencerMeta( meta_key = metaColumns, userID = arguments.userID )>					

					<!--- If exist? Deleting the data. --->
					<cfif local.isExist.recordCount GT 0>						

						<cfset application.influencerMetaObj.deleteInfluencerMeta( metaColumns = metaColumns ,userID = arguments.userID)>


						<cfquery name="local.influencersOptions" datasource="#variables.datasource#">

							DELETE FROM influencers_options 
								WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
								AND   optionTypeID IN( <cfqueryparam value="1,2" cfsqltype="cf_sql_varchar" list="true"> )

						</cfquery>

						<cfset deleteTags( userID = arguments.userID , entityID = arguments.userID, entityTypeID = 31)>

					</cfif>
					<!--- END ::check whether the meta data is exist or not --->

					<!--- START:: insert meta data --->
					<cfset local.attributes = {} >
					<cfset local.attributes['freq_post'] 		= arguments.freq_post>
					<cfset local.attributes['freq_review'] 		= arguments.freq_review>					
					
					<cfloop collection="#local.attributes#" item="key">
						
						<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = key, meta_value = structFind(local.attributes, key), userID = arguments.userID )>

					</cfloop>

					<!--- START::insert influencers option value  --->

					<cfif structKeyExists(arguments,'programsName') AND arrayLen(arguments.programsName) GT 0>
						
						<cfset insertInfluencerOptions(userID = arguments.userID ,optionName = arguments.programsName ,optionTypeID = 1)>

					</cfif>

					<cfif structKeyExists(arguments,'promotionsName') AND arrayLen(arguments.promotionsName) GT 0>

						<cfset insertInfluencerOptions(userID = arguments.userID , optionName = arguments.promotionsName ,optionTypeID = 2)>

					</cfif>
					<!--- END::insert influencers option value  --->

					<!--- START :: insert influencers brandsLove data in tagging table --->
					<cfif structKeyExists(arguments,'brandsLove') AND arrayLen(arguments.brandsLove) GT 0>

						<cfset local.attributes	= structNew() >				

						<cfloop array="#arguments.brandsLove#" index="local.brandsLove">

							<cfset structClear(local.attributes) >

							<cfset local.attributes['tags'] 		 = local.brandsLove >
							<cfset local.attributes['userID'] 		 = arguments.userID >
							<cfset local.attributes['auth_token'] 	 = arguments.auth_token >
							<cfset local.attributes['entityID']   	 = arguments.userID >
							<cfset local.attributes['entityTypeID']  = 31 >

							<cfset local.brandsLove 	= httpRequest(methodName = "POST", endPointOfURL = "/tags/", timeout = 3000, parameters = local.attributes) >	

						</cfloop>
					</cfif>

					<!--- END :: insert influencers brandsLove data in tagging table --->

					<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = 'score', meta_value = application.scoreObj.getInfluencerScore( userID = arguments.userID ), userID = arguments.userID )>

					<!--- END:: insert meta data --->
					<cfset result.message = application.messages['influencersMeta_post_activity_success']>
					<cfset result.status =  true>
					<cfset result.error = false>

					<cfreturn representationOf(result).withStatus(200)>

				</cfcase>
				<!--- END:: Activity tab functionality --->

				<!--- START:: platforms tab functionality --->
				<cfcase value="platforms">
					
					<cfparam name="arguments.freq_post_social" 		type="string" 	default="0">
					<cfparam name="arguments.freq_post_video" 		type="string" 	default="0">
					<cfparam name="arguments.score" 	 			type="numeric"  default="0">
					<cfparam name="arguments.socialMediaName" 		type="array" 	default="#arrayNew()#">
					<cfparam name="arguments.websitesName"    		type="array"	default="#arrayNew()#">

					<!--- START ::check whether the meta data is exist or not --->
					<cfset metaColumns = 'freq_post_social,freq_post_video,score'>
					<cfset local.isExist = application.influencerMetaObj.getInfluencerMeta( meta_key = metaColumns, userID = arguments.userID )>					

					<!--- If exist? Deleting the data. --->
					<cfif local.isExist.recordCount GT 0>

						<cfset application.influencerMetaObj.deleteInfluencerMeta( metaColumns = metaColumns ,userID = arguments.userID)>

						<cfquery name="local.influencersOptions" datasource="#variables.datasource#">

							DELETE FROM influencers_options 
								WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
								AND   optionTypeID IN( <cfqueryparam value="3,4" cfsqltype="cf_sql_varchar" list="true"> )
						</cfquery>

					</cfif>
					<!--- END ::check whether the meta data is exist or not --->

					<!--- START:: insert meta data --->
					<cfset local.attributes = {} >
					<cfset local.attributes['freq_post_social'] 	= arguments.freq_post_social>
					<cfset local.attributes['freq_post_video'] 		= arguments.freq_post_video>					
					
					<cfloop collection="#local.attributes#" item="key">
						
						<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = key, meta_value = structFind(local.attributes, key), userID = arguments.userID )>

					</cfloop>

					<!--- START:: insert influencers option data --->
					<cfif structKeyExists(arguments,'socialMediaName') AND arrayLen(arguments.socialMediaName) GT 0>

						<cfset insertInfluencerOptions(userID = arguments.userID ,optionName  = arguments.socialMediaName ,optionTypeID = 3 )>

					</cfif>

					<cfif structKeyExists(arguments,'websitesName') AND arrayLen(arguments.websitesName) GT 0>

						<cfset insertInfluencerOptions(userID = arguments.userID ,optionName = arguments.websitesName ,optionTypeID = 4 )>

					</cfif>
					<!--- END:: insert influencers option data --->

					<!--- END:: insert meta data --->

					<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = 'score', meta_value = application.scoreObj.getInfluencerScore( userID = arguments.userID ), userID = arguments.userID )>

					<cfset result.message = application.messages['influencersMeta_post_platforms_success']>

					<cfset result.status =  true>
					<cfset result.error = false>

					<cfreturn representationOf(result).withStatus(200)>

				</cfcase>
				<!--- END:: platforms tab functionality --->

				<!--- START:: foodPreferences tab functionality --->
				<cfcase value="foodPreferences">
					
					<cfparam name="arguments.freq_cook" 	   	type="string"  default="" >
					<cfparam name="arguments.freq_tea" 		   	type="string"  default="" >
					<cfparam name="arguments.freq_soda"      	type="string"  default="" >
					<cfparam name="arguments.freq_alcohol"      type="string"  default="" >
					<cfparam name="arguments.freq_coffee"      	type="string"  default="" >
					<cfparam name="arguments.rate_eco"      	type="string"  default="" >
					<cfparam name="arguments.interest_organic" 	type="string"  default="" >
					<cfparam name="arguments.score" 	 		type="numeric" default="0">
					<cfparam name="arguments.meat_dairy"		type="string"  default="" >
					
					<cfparam name="arguments.food_love" 			type="array" default="#arrayNew()#" >
					<cfparam name="arguments.food_avoid" 			type="array" default="#arrayNew()#" >
					<cfparam name="arguments.influencers_allergy"	type="array" default="#arrayNew()#" >
					<cfparam name="arguments.influencers_channel" 	type="array" default="#arrayNew()#" >
					<cfparam name="arguments.influencers_cuisine" 	type="array" default="#arrayNew()#" >
					<cfparam name="arguments.influencers_diet" 		type="array" default="#arrayNew()#" >
					<cfparam name="arguments.groceriesName"			type="array" default="#arrayNew()#" >				
					
					<!--- START ::check whether the meta data is exist or not --->
					<cfset metaColumns = 'freq_cook,freq_tea,freq_soda,freq_alcohol,freq_coffee,rate_eco,meat_dairy,interest_organic,score'>
					<cfset local.isExist = application.influencerMetaObj.getInfluencerMeta( meta_key = metaColumns, userID = arguments.userID )>

					<!--- If exist? Deleting the data. --->
					<cfif local.isExist.recordCount GT 0>

						<cfset application.influencerMetaObj.deleteInfluencerMeta( metaColumns = metaColumns ,userID = arguments.userID)>

						<cfquery name="local.influencersOptions" datasource="#variables.datasource#">

							DELETE FROM influencers_options
									WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
										AND optionTypeID = <cfqueryparam value="6" cfsqltype="cf_sql_integer">


						</cfquery>

						<cfquery name="local.influencersAllergy" datasource="#variables.datasource#">

							DELETE FROM influencers_allergy
									WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">									

						</cfquery>

						<cfquery name="local.influencersChannel" datasource="#variables.datasource#">

							DELETE FROM influencers_channel
									WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">									

						</cfquery>

						<cfquery name="local.influencersCuisine" datasource="#variables.datasource#">

							DELETE FROM influencers_cuisine
									WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">									

						</cfquery>

						<cfquery name="local.influencersDiet" datasource="#variables.datasource#">

							DELETE FROM influencers_diet
									WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">									

						</cfquery>

						<cfset deleteTags( userID = arguments.userID , entityID = arguments.userID, entityTypeID = 32)>
						<cfset deleteTags( userID = arguments.userID , entityID = arguments.userID, entityTypeID = 33)>

					</cfif>				
					<!--- END ::check whether the meta data is exist or not --->

					
					<!--- START :: Inserting influencer_Meta table details --->
					<cfset local.attributes = {} >

					<cfset local.attributes['freq_cook'] 		= arguments.freq_cook>
					<cfset local.attributes['freq_tea'] 		= arguments.freq_tea>
					<cfset local.attributes['freq_soda'] 		= arguments.freq_soda>
					<cfset local.attributes['freq_alcohol'] 	= arguments.freq_alcohol>
					<cfset local.attributes['freq_coffee'] 		= arguments.freq_coffee>
					<cfset local.attributes['rate_eco'] 		= arguments.rate_eco>
					<cfset local.attributes['interest_organic'] = arguments.interest_organic>					
					<cfset local.attributes['meat_dairy'] 		= getInfluencerOptionID( optionName = '#arguments.meat_dairy#', optionTypeID = 5 )>
					
					<cfloop collection="#local.attributes#" item="key">
						
						<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = key, meta_value = structFind(local.attributes, key), userID = arguments.userID )>

					</cfloop>
					<!--- END :: Inserting influencer_Meta table details --->

					<!--- START:: calling tags post to insert food_love the tag --->

					<cfloop array="#arguments.food_love#" index="local.food_love" >

						<cfset structClear(local.attributes) >

						<cfset local.attributes['tags'] 		= local.food_love >
						<cfset local.attributes['userID'] 		= arguments.userID >
						<cfset local.attributes['auth_token'] 	= arguments.auth_token >
						<cfset local.attributes['entityID'] 	= arguments.userID >
						<cfset local.attributes['entityTypeID'] = 32 >

						<cfset getTagResponse = httpRequest( methodName = 'POST', endPointOfURL = '/tags', timeout = 3000, parameters = local.attributes ) >
						
					</cfloop>

					<!--- END:: calling tags post to insert food_love the tag --->

					<!--- START:: calling tags post to insert food_avoid the tag --->
					<cfif structKeyExists(arguments,'food_avoid') AND arrayLen(arguments.food_avoid) GT 0>

						<cfloop array="#arguments.food_avoid#" index="local.food_avoid" >

							<cfset structClear(local.attributes) >

							<cfset local.attributes['tags'] 		= local.food_avoid >
							<cfset local.attributes['userID'] 		= arguments.userID >
							<cfset local.attributes['auth_token'] 	= arguments.auth_token >
							<cfset local.attributes['entityID'] 	= arguments.userID >
							<cfset local.attributes['entityTypeID'] = 33 >

							<cfset getTagResponse = httpRequest( methodName = 'POST', endPointOfURL = '/tags', timeout = 3000, parameters = local.attributes ) >
							
						</cfloop>

					</cfif>
					<!--- END:: calling tags post to insert food_avoid the tag --->

					<!--- START:: Insert influencerAllergy tag --->
					<cfif structKeyExists(arguments,'influencers_allergy') AND arrayLen(arguments.influencers_allergy) GT 0>

						<cfquery name="local.influencerAllergy" datasource="#variables.datasource#" >
							INSERT INTO influencers_allergy(
									userID,
									allergyID
									) 
								SELECT #arguments.userID#, allergyID 
										FROM val_recipe_allergy
										WHERE allergyName in (
											<cfloop array="#arguments.influencers_allergy#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.influencers_allergy, element ) NEQ arrayLen( arguments.influencers_allergy )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>
					<!--- END:: Insert influencerAllergy tag --->

					<!--- START:: Insert influencerChennal tag --->
					<cfif structKeyExists(arguments,'influencers_channel') AND arrayLen(arguments.influencers_channel) GT 0>

						<cfquery name="local.influencerChennal" datasource="#variables.datasource#" >
							INSERT INTO influencers_channel(
									userID,
									channelID
									) 
								SELECT #arguments.userID#, channelID 
										FROM val_recipe_channel
										WHERE channelName in (
											<cfloop array="#arguments.influencers_channel#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.influencers_channel, element ) NEQ arrayLen( arguments.influencers_channel )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>
					<!--- END:: Insert influencerChennal tag --->

					<!--- START:: Insert influencerCuisine tag --->

					<cfif structKeyExists(arguments,'influencers_cuisine') AND arrayLen(arguments.influencers_cuisine) GT 0>

						<cfquery name="local.influencerCuisine" datasource="#variables.datasource#" >
							INSERT INTO influencers_cuisine(
									userID,
									cuisineID
									) 
								SELECT #arguments.userID#, cuisineID 
										FROM val_recipe_cuisine
										WHERE cuisineName in (
											<cfloop array="#arguments.influencers_cuisine#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.influencers_cuisine, element ) NEQ arrayLen( arguments.influencers_cuisine )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>
					<!--- END:: Insert influencerCuisine tag --->

					<!--- START:: Insert influencerDiet tag --->
					<cfif structKeyExists(arguments,'influencers_diet') AND arrayLen(arguments.influencers_diet) GT 0>

						<cfquery name="local.influencerDiet" datasource="#variables.datasource#" >
							INSERT INTO influencers_diet(
									userID,
									dietID
									) 
								SELECT #arguments.userID#, dietID 
										FROM val_recipe_diet
										WHERE dietName in (
											<cfloop array="#arguments.influencers_diet#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.influencers_diet, element ) NEQ arrayLen( arguments.influencers_diet )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>
					<!--- END:: Insert influencerDiet tag --->

					<!--- START:: Insert influencers_options details --->	
					<cfif structKeyExists(arguments,'groceriesName') AND arrayLen(arguments.groceriesName) GT 0>

						<cfset insertInfluencerOptions( userID = arguments.userID , optionName = arguments.groceriesName, optionTypeID = 6 )>

					</cfif>
					<!--- END:: Insert influencers_options details --->

					<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = 'score', meta_value = application.scoreObj.getInfluencerScore( userID = arguments.userID ), userID = arguments.userID )>

					<cfset result.message = application.messages['influencersMeta_post_foodpreference_success']>

					<cfset result.status =  true>
					<cfset result.error = false>

					<cfreturn representationOf(result).withStatus(200)>

				</cfcase>
				<!--- END:: foodPreferences tab functionality --->

				<!--- START:: demographics tab functionality --->
				<cfcase value="demographics">
					
					<cfparam name="arguments.age" 			type="string"  default="0">
					<cfparam name="arguments.income" 		type="string"  default="0">
					<cfparam name="arguments.children" 		type="string"  default="0">
					<cfparam name="arguments.education"    	type="string"  default="0">
					<cfparam name="arguments.ethnicity"    	type="string"  default="0">
					<cfparam name="arguments.score"    	    type="numeric" default="0">

					<!--- START ::check whether the meta data is exist or not --->
					<cfset metaColumns = 'age,income,children,education,ethnicity,score'>
					<cfset local.isExist = application.influencerMetaObj.getInfluencerMeta( meta_key = metaColumns, userID = arguments.userID )>					

					<!--- If exist? Deleting the data. --->	
					<cfif local.isExist.recordCount GT 0>

						<cfset application.influencerMetaObj.deleteInfluencerMeta( metaColumns = metaColumns ,userID = arguments.userID)>

					</cfif>
					<!--- END ::check whether the meta data is exist or not --->

					<cfset local.attributes = structNew()>

					<!--- START:: select ageID  --->
					<cfif structKeyExists(arguments, "age") AND arguments.age NEQ "">

						<cfquery name="local.age" datasource="#variables.datasource#">

							SELECT ageID FROM val_demographics_age
								WHERE ageName = <cfqueryparam value="#trim(arguments.age)#" cfsqltype="cf_sql_varchar">

						</cfquery>

						<cfset local.attributes['age'] 			= local.age.ageID>

					</cfif>

					<!--- START:: select incomeID  --->
					<cfif structKeyExists(arguments, "income") AND arguments.income NEQ "">
						
						<cfquery name="local.income" datasource="#variables.datasource#">
							SELECT incomeID FROM val_demographics_income
								WHERE incomeName = <cfqueryparam value="#trim(arguments.income)#" cfsqltype="cf_sql_varchar">
						</cfquery>

						<cfset local.attributes['income'] 		= local.income.incomeID>
						
					</cfif>

					<!--- START:: select children  --->
					<cfif structKeyExists(arguments, "children") AND arguments.children NEQ "">

						<cfquery name="local.children" datasource="#variables.datasource#">
							SELECT childrenID FROM val_demographics_children
								WHERE childrenName = <cfqueryparam value="#trim(arguments.children)#" cfsqltype="cf_sql_varchar">
						</cfquery>

						<cfset local.attributes['children'] 	= local.children.childrenID>

					</cfif>

					<!--- START:: select education  --->
					<cfif structKeyExists(arguments, "education") AND arguments.education NEQ "">

						<cfquery name="local.education" datasource="#variables.datasource#">

							SELECT educationID FROM val_demographics_education
								WHERE educationName = <cfqueryparam value="#trim(arguments.education)#" cfsqltype="cf_sql_varchar">

						</cfquery>

						<cfset local.attributes['education'] 	= local.education.educationID>

					</cfif>

					<!--- START:: select ethnicity  --->
					<cfif structKeyExists(arguments, "ethnicity") AND arguments.ethnicity NEQ "">

						<cfquery name="local.ethnicity" datasource="#variables.datasource#">

							SELECT ethnicityID FROM val_demographics_ethnicity
								WHERE ethnicityName = <cfqueryparam value="#trim(arguments.ethnicity)#" cfsqltype="cf_sql_varchar">

						</cfquery>

						<cfset local.attributes['ethnicity'] 	= local.ethnicity.ethnicityID>
						
					</cfif>					
					
					<!--- START:: insert meta data --->
					
					<cfloop collection="#local.attributes#" item="key">
						
						<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = key, meta_value = structFind(local.attributes, key), userID = arguments.userID )>

					</cfloop>
					<!--- END:: insert meta data --->

					<cfset application.influencerMetaObj.insertInfluencerMeta( meta_key = 'score', meta_value = application.scoreObj.getInfluencerScore( userID = arguments.userID ), userID = arguments.userID )>
					
					<cfset result.message = application.messages['influencersMeta_post_demographics_success']>

					<cfset result.status =  true>
					<cfset result.error = false>

					<cfreturn representationOf(result).withStatus(200)>

				</cfcase>
				<!--- END:: demographics tab functionality --->

			</cfswitch>

			<cfcatch>		

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /blogs/POST", errorCatch = variables.cfcatch  )>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />
				
			</cfcatch>

		</cftry>

	</cffunction>

	<!--- ************************************************** --->
	<!--- ************    Private functions   ************** --->
	<!--- ************************************************** --->

	<cffunction name="insertInfluencerOptions" access="private" output="false" hint="used to insert the influencer_options details">

		<cfargument name="userID" 		type="numeric" 	required="true">
		<cfargument name="optionName" 	type="array" 	required="true">
		<cfargument name="optionTypeID" type="string" 	required="true">

		<cfquery name="local.InsertPrograms" datasource="#variables.datasource#">
			
			INSERT INTO influencers_options(
					userID,
					optionID,
					optionTypeID
					)
					SELECT  #arguments.userID#,
							optionID,
							#arguments.optionTypeID# 
						FROM val_influencer_options 
						WHERE optionName IN
							(
								<cfloop array="#arguments.optionName#" index="element">						
									<cfqueryparam value="#element#" cfsqltype="cf_sql_varchar">
									<cfif ArrayFindNoCase( arguments.optionName, element ) NEQ ArrayLen( arguments.optionName )>,<cfelse>);</cfif>
								</cfloop>
		</cfquery>

		<cfreturn />

	</cffunction>

	<cffunction name="deleteTags" access="private" output="false" hint="used to delete the tag details for an influencer.">

		<cfargument name="entityID" 	type="numeric" required="true">
		<cfargument name="entityTypeID" type="numeric" required="true">
		<cfargument name="userID" 		type="numeric" required="true">

		<cfquery name="local.removeTags" datasource="#variables.datasource#">
			
			DELETE FROM tagging 
				WHERE entityID 		= <cfqueryparam value="#arguments.entityID#" 		cfsqltype="cf_sql_integer">
				AND entityTypeID 	= <cfqueryparam value="#arguments.entityTypeID#" 	cfsqltype="cf_sql_integer">
				AND userID 			= <cfqueryparam value="#arguments.userID#" 			cfsqltype="cf_sql_integer">

		</cfquery>		

		<cfreturn />

	</cffunction>	

	<cffunction name="getInfluencerOptionID" returntype="Numeric" access="private" hint="used to get the optionID from the val_influencer_options table.">
		<cfargument name="optionName" 	type="string" 	required="true">
		<cfargument name="optionTypeID" type="numeric" 	required="true">

		<cfquery name="local.getInfluencerOptionID" datasource="#variables.datasource#">

			SELECT optionID 
				FROM val_influencer_options
				WHERE optionName = <cfqueryparam value="#arguments.optionName#" cfsqltype="cf_sql_varchar">
					AND optionTypeID = <cfqueryparam value="#arguments.optionTypeID#" cfsqltype="cf_sql_numeric">

		</cfquery>

		<cfif local.getInfluencerOptionID.recordCount NEQ 0 >
			
			<cfreturn local.getInfluencerOptionID.optionID>

		<cfelse>
			
			<cfreturn 0 >

		</cfif>
		
	</cffunction>

	<cffunction name="influencerEmptyMetaDetails" access="private" output="false" hint="used to set a default value for the influencer_meta.">

		<cfargument name="columns" type="string" required="true">

		 <cfset local.influencersMeta = structNew()>

		 <cfloop list="#arguments.columns#" index="element">
		 
		 	<cfset structInsert(local.influencersMeta, element, '')>

		 </cfloop>
		
		<cfreturn local.influencersMeta>
			
	</cffunction>

	
	<cffunction name="getOptions" access="private" output="false">

		<cfargument name="optionTypeID"		type="numeric" required="true">
		<cfargument name="userID"			type="numeric" required="true">

		<cfquery name="local.influencersOptions" datasource="#variables.datasource#">

			SELECT vio.optionName 
				FROM influencers_options AS io 
				INNER JOIN val_influencer_options AS vio
				ON io.optionID = vio.optionID
				WHERE io.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
				AND io.optionTypeID = <cfqueryparam value="#arguments.optionTypeID#" cfsqltype="cf_sql_integer">
									

		</cfquery> 

		<cfset local.optionNames = arrayNew()>

		<cfloop query="local.influencersOptions">

			<cfset arrayAppend(local.optionNames, optionName)>

		</cfloop>

		<cfreturn local.optionNames>

	</cffunction>	

</cfcomponent>