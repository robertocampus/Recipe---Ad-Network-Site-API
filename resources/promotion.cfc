<cfcomponent extends="taffyAPI.base" taffy:uri="/promotion/{id}" hint="Return Contest Details.">
	
	<cffunction name="GET" access="public" hint="Return Contest Details" output="false">
		<cfargument name="id" type="numeric" required="true" hint="Item ID" >
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result.message 	= "" />

		<cftry>

		    <cfquery datasource="#variables.datasource#" name="result.query" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
				SELECT 	
					C.*,
					P.*,
					S.*,
					VR.*,
					VC.*,
					
					P.prizeName,
					P.prizeDescription,
					P.prizeText,

					U.userAbout AS 'about',

					st.stateName,

					CONCAT( CI.imagePath, '/', CI.imageName )			AS 'contest_FullSize_imageName',
					CONCAT( CI.imagePath, '/', CI.imageThumbFileName )	AS 'contest_Thumb_Image', 
					CONCAT( CI.imagePath, '/', CI.imageFileNameHalf )	AS 'contest_mini_Image',
				 
					CONCAT( SI.imagePath, '/', SI.imageName )			AS 'sponsor_FullSize_imageName',
					CONCAT( SI.imagePath, '/', SI.imageThumbFileName )	AS 'sponsor_Thumb_Image', 
					CONCAT( SI.imagePath, '/', SI.imageFileNameHalf )	AS 'sponsor_mini_Image', 

					CONCAT( PI.imagePath, '/', PI.imageName )			AS 'prize_FullSize_imageName',
					CONCAT( PI.imagePath, '/', PI.imageThumbFileName )	AS 'prize_Thumb_Image', 
					CONCAT( PI.imagePath, '/', PI.imageFileNameHalf )	AS 'prize_mini_Image',
					lcase(VC.contestTypeName) AS contestTypeName,
					
					( SELECT count(*) FROM comments CM WHERE CM.entityID = C.contestID AND CM.entityTypeID = 5 AND CM.active = 1 ) as CommentCount,
						
				    CASE 
				        WHEN ((datediff(DATE(NOW()), contestExpireDate))<1) THEN 0
				        ELSE 1
					END AS isExpired
					
				FROM contests C
			
				LEFT JOIN val_contesttype VC ON VC.contestTypeID = C.contestTypeID
				LEFT JOIN val_contestregion VR ON VR.contestRegionID = C.contestRegionID
				
				LEFT JOIN images CI ON CI.imageID = C.imageID
									
				LEFT JOIN sponsors S ON S.sponsorID = C.sponsorID
				LEFT JOIN val_states st ON st.stateID = S.sponsorStateID

				LEFT JOIN users U ON U.userID = S.userID
				LEFT JOIN images SI ON SI.entityID  = S.sponsorID AND SI.entityTypeID = 20

				LEFT JOIN prizes P  ON  P.prizeID  = C.prizeID
				LEFT JOIN images PI ON PI.entityID = P.prizeID AND PI.entityTypeID = 22
				
				WHERE C.contestID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
			 	 	 	
			</cfquery>
		   
		  	<cfcatch>			
		  		
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'promotion_get_found_success', error = variables.cfcatch)>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /promotion/ GET", errorCatch = variables.cfcatch  )>	
			  
			  	<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
	    </cftry>

	    <cfset result.status  	= true />
	    <cfset result.message = application.messages['promotion_get_found_success'] />

	  	<cfset local.tmp = logAction( actionID = 201, extra = "method: /promotion/ GET"  )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	

</cfcomponent>