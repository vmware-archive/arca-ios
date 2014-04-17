>#ArcaSync
>Knowing, not storing

ArcaSync uses all of the information made available through the ArcaBridge, and CoreData, to know about your data, instead of just store it. It takes everything you tell it about your data and uses that to determine how and when to fill in the blanks, and keep your remote store (i.e. server) up to date.

Because ArcaSync is based around local-first caching, it allows you to be transactional with your information. It takes a lot of the complexity out of hard problems like ensuring ordered delivery of updates to a server. Ensuring that a photo is uploaded to the an image server before the post that revolves around it is sent out becomes a simple, automated event.

##Key Features
- Facilitates transactions by providing versioned change information.
- A configurable, and customizable, system for keeping data up-to-date.
- Data preservation for interrupted connectivity or app closure.
