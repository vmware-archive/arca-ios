#Contributing Guide
##Fork And Pull
As with most open source projects on GitHub, we work on a system of pull requests. A great guide by GitHub is available [here](https://help.github.com/articles/using-pull-requests). Please read this document through before you **begin** this process, so you don't end up with a mess for either of us.

##The Golden Rules
###Commit Small
If you send us a pull request with eight hundred lines of code in a single commit, we're likely to reject it. It's nothing personal, but even internally we try to keep commits small and to the point. The exceptions for everyone is when you are adding a completely novel functionality -- sometimes a single commit can make sense.

###Work From Issues
We'd really like it if you worked form the issues on GitHub (even if that means submitting an issue, then working on it). We work from issues ourselves, so it makes it a natural way for everyone to stay in sync. We probably wouldn't reject a request outright, but you wouldn't become our best friend.

###Only Work From Development
Never work from, or submit a request to, either *testing* or *production*. Any request that doesn't both originate from and target development will be summarily rejected.

###Format Your Commits
Your commits should look like this:

	50 characters or less                                                           
                                                                                
	This is a paragraph explaining what the issue was, and how it was fixed. The    
	entire commit message must be manually wrapped at 80 or fewer characters. This  
	ensures proper display on all terminals, and on web tools such as GitHub.       
                                                                                
	 - Include a tl;dr version in bullets                                           
                                                                                
	 - Which should be a space, a hyphen, and then one or two lines of text         
                                                                                
	 - Always separate your bullets by a blank line, for readability
	
Here's a proper example

	Fixes #6: Added type check                                                      
                                                                                
	The issue was caused by a missing type check, which in some cases resulted in   
	-length being called on something other than an NSArray. The type check has      
	been added, and an NSException is now raised to alert the developer that they   
	are using the framework incorrectly.                                            
                                                                                
	 - Added type check in [SomeClass someFunction:]                                
                                                                                
	 - Added NSException when type check fails                                      
                                                                                
	 - Added constants for the exception name/reason
	
