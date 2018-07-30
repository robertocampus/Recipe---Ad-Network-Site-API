<cfcomponent extends="taffyAPI.base" taffy_uri="/tickets/" hint="Using this user can able to <code>POST</code> a  ticket details">

	<cffunction name="POST" access="public" 	hint="Insert Support Ticket Record" returntype="struct" output="true">
		<cfargument name="blogID"	  			type="string" 	required="false" default="0"  hint="Blog ID">
		<cfargument name="ticketText"			type="string" 	required="false" default=""  hint="Text of ticket">
		<cfargument name="ticketStatusID"		type="string" 	required="false" default="1" hint="">
		<cfargument name="ticketIssueTypeID"	type="string" 	required="false" default="1" hint="">
 		<cfargument name="ticketName"			type="string" 	required="false" default=""  hint="Name of user that opened ticket">
		<cfargument name="ticketEmail"			type="string" 	required="false" default=""  hint="Email address of user that opened ticket">		
		<cfargument name="ticketUrl"			type="string" 	required="false" default=""  hint="URL given by user that opened ticket">
		<cfargument name="userID"				type="numeric" 	required="false" default="0" hint="UserID">
  	
		<!--- :: init result structure --->	
		<cfset var result		= StructNew() />
		<cfset var local		= StructNew() />
		<cfset result['status']	= false />
		<cfset result['message'] = ''>
<!--- 
DROP TABLE IF EXISTS `supporttickets`;
CREATE TABLE  `supporttickets` (
  `ticketID` int(10) unsigned NOT NULL auto_increment,
  `ticketText` text,
  `ticketStatusID` int(10) unsigned default '1',
  `ticketIssueTypeID` int(10) unsigned default '0',
  `ticketCreateDate` datetime default '0000-00-00 00:00:00',
  `ticketUpdateDate` varchar(45) default '0000-00-00 00:00:00',
  `ticketCloseDate` datetime default '0000-00-00 00:00:00',
  `ticketEmail` varchar(100) default NULL,
  `ticketName` varchar(100) default NULL,
  `ticketURL` varchar(255) default NULL,
  `ticketIP` varchar(100) default '0.0.0.0',
  `userID` int(10) unsigned default NULL,
  `blogID` int(10) unsigned default NULL,
  `active` tinyint(3) unsigned default '1',
  PRIMARY KEY  (`ticketID`),
  KEY `Index_CreateDate` (`ticketCreateDate`),
  KEY `Index_StatusID` (`ticketStatusID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;
--->
 
		<cftry>
		
			<cfquery datasource="#variables.datasource#" name="local.query">
			INSERT INTO supporttickets 
						( 
							ticketText, 
							ticketStatusID, 
							ticketIssueTypeID, 
							ticketCreateDate,
							ticketEmail,
							ticketName,
							ticketURL, 
							ticketIP,
							userID,
							blogID,
							active
						)
			VALUES  (
						<cfqueryparam cfsqltype="cf_sql_varchar"	value="#arguments.ticketText#"			   maxlength="65535">,
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.ticketStatusID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.ticketIssueTypeID#">,
						<cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >,
						<cfqueryparam cfsqltype="cf_sql_varchar" 	value="#left(arguments.ticketEmail, 100)#" maxlength="100">,
						<cfqueryparam cfsqltype="cf_sql_varchar" 	value="#left(arguments.ticketName, 100)#"  maxlength="100">,
						<cfqueryparam cfsqltype="cf_sql_varchar" 	value="#left(arguments.ticketURL, 255)#"   maxlength="255">,
						<cfqueryparam cfsqltype="cf_sql_varchar"   value="#cgi.REMOTE_ADDR#">,					 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.blogID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer" value="1">
					)
			</cfquery>		
			
			<cfquery datasource="#variables.datasource#" name="local.getLast"> 
				SELECT LAST_INSERT_ID() AS ID
			</cfquery>
   		
			<cfcatch> 
				<cfset result.message = errorMessage(message ='tickets_post_add_error', error = variables.cfcatch)>
				<!--- // 251, 'Support: Error on Insert Ticket', 'Error encountered while inserting support ticket.', 1 --->
				<cfset logAction( actionID = 251, extra = "method: /tickets/POST", errorCatch = variables.cfcatch)>	
				<cfreturn noData().withStatus(500)>

			</cfcatch> 

		</cftry>
  
		<!--- // 252, 'Support: Ticket Inserted', 'Support ticket inserted successfully.', 1 --->
		<cfset logAction( actionID = 252, extra = "method: /tickets/POST")>	
		 							
		<cfset result.ticketID = local.getLast.ID />	
      	<cfset result.status = true>
		<cfset result.message = application.messages['tickets_post_add_success']>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	 

</cfcomponent>
