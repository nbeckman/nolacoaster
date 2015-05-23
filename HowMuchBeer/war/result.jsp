<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="com.howmuchbeer.main.BeerEventRecord" %>
<%@ page import="com.howmuchbeer.main.Calculations" %>
<%@ page import="com.howmuchbeer.main.PMF" %>
<%@ page import="com.howmuchbeer.containers.BasicAssortment" %>
<%@ page import="java.util.List" %>
<%@ page import="javax.jdo.PersistenceManager" %>

<html>
<head><title>How Much Beer? Results</title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-21951229-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
</head>

<style type="text/css">
div.one
{
width: 200px; height: 200px;
border-style: solid;
border-color: #002200;
background-color: #aaeeaa;
padding: 5px;
margin-left: 2em;
}
</style>

<body>


<div style="padding:0;margin:0;background:#123456"> 
<div style="margin-left:15%;width:650px;background:#ABCDEF;border-left:2px solid #567890;border-right:10px solid #567890;border-bottom:5px solid #567890;padding:1em"> 
<img style="margin:0px auto;display:block" src="/images/howmuchbeerlogo.png"/>
<h1>Results</h1>

<%
    String craziness = request.getParameter("craziness");

    // Do query
    PersistenceManager pm = PMF.get().getPersistenceManager();
    String query = "select from " + BeerEventRecord.class.getName() + " where partyCraziness=='" + craziness + "'";
    List<BeerEventRecord> events = (List<BeerEventRecord>) pm.newQuery(query).execute();
    
    // We are going to completely ignore events. This database is now so full of spam that
    // the results are crap. We'll just hardcode the output. :-(
    long average_oz;
    if ("WILD".equals(craziness)) {
    	// 5 beers per person.
    	average_oz = 5 * 12;
    } else if ("CHILL".equals(craziness)) {
    	// 1.5 beers per person.
    	average_oz = 18;
    } else {
       // 3 beers per person.
    	average_oz = 3 * 12;
    }
    boolean was_long = true;
    Long attendees = Long.valueOf(0);
    try {
      attendees = Long.parseLong(request.getParameter("attendees"));
      if (attendees < 0 ) {
    	  attendees = Long.valueOf(0);
      }
    } catch(NumberFormatException nfe) {
      was_long = false;
    }
      
    if (was_long) {
      // So, if you're in here, we are go for printing out shit.
      long std_dev = Calculations.stdDev(events);
      long mean_ounces = average_oz * attendees;
      long above_ounces = mean_ounces + std_dev;
      long below_ounces = mean_ounces - std_dev;
      below_ounces = below_ounces < 0 ? 0 : below_ounces;
%>
    <p>So you're having a <%=craziness%> party with <%=attendees%> people?

    <div class="one">
    <p>For an average party, you should buy:
      <ul>
      <%
        for(String s : new BasicAssortment().resultsForOunces(mean_ounces)) {
      %>
        <li><b><%=s%></b>
      <%
        } 
      %>
      </ul>
    </div>
<%  } else { %>
    <p> Uh oh, the number of attendees, <%=request.getParameter("attendees")%>, is not a number!
<%
  }
%>
<div class="clear"></div>
</div>
</div>
</body>
</html>