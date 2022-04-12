IMPORT os
IMPORT JAVA java.lang.System
IMPORT JAVA java.lang.String
IMPORT JAVA java.lang.Object
IMPORT JAVA java.util.Properties
IMPORT JAVA javax.mail.Session
IMPORT JAVA javax.mail.Authenticator
IMPORT JAVA javax.mail.Message
IMPORT JAVA javax.mail.Message.RecipientType
IMPORT JAVA javax.mail.internet.MimeMessage
IMPORT JAVA javax.mail.internet.InternetAddress
IMPORT JAVA com.sun.mail.smtp.SMTPTransport
DEFINE optarr DYNAMIC ARRAY OF STRING

MAIN
  DEFINE user,pass,from,to,host,subject,bodyfile,body,proto STRING
  DEFINE sess Session
  DEFINE props Properties
  DEFINE msg MimeMessage
  DEFINE mynull Object
  DEFINE trans SMTPTransport
  DEFINE port,arg,space STRING
  DEFINE i,len,tls INTEGER
  TYPE object_array_t ARRAY[] OF java.lang.Object
  DEFINE sarr object_array_t
  LET sarr = object_array_t.create(1)
  LET proto="smtp"
  LET port=587
  LET tls=1


  FOR i=0 TO num_args()
    LET arg=arg_val(i)
    LET len=arg.getLength()

&define GETOPT(aopt,shortopt,longopt,desc) \
    IF i==0 THEN \
      LET space=IIF(length(longopt)>=8,"\t","\t\t") \
      LET optarr[optarr.getLength()+1]=shortopt,"     ",longopt,space," <",desc,">" \
    ELSE \
      IF arg==shortopt OR arg==longopt THEN \
        LET i=i+1 \
        LET aopt=arg_val(i) \
        CONTINUE FOR \
      END IF \
    END IF


    GETOPT(from,"-f","--from","Sender")
    GETOPT(to,"-t","--to","Recipient(s) comma separated")
    GETOPT(subject,"-s","--subject","Mail subject")
    GETOPT(bodyfile,"-b","--bodyfile","text filename for mail body")
    GETOPT(host,"-h","--host","smtp host")
    GETOPT(port,"-p","--port","smtp port, can be 25,465 or 587, default:587")
    GETOPT(user,"-u","--user","smtp username")
    GETOPT(pass,"-w","--password","smtp password (plaintext)")
    GETOPT(proto,"-c","--protocol","can be 'smtp' or 'smtps', default:smtp")
    GETOPT(tls,"-l","--tls","enable tls, can be 0 or 1, default:1")
    IF i==0 THEN CONTINUE FOR END IF
    -- process result_file according to system path
    IF arg.getCharAt(1) = '-' THEN
      DISPLAY SFMT("Option %1 is unknown.", arg)
      CALL help()
    END IF

  END FOR
  IF num_args()=0 THEN
    CALL help()
  END IF
  CALL checkNULL(host,"Host must be given via '--host'")
  CALL checkNULL(subject,"Subject must be given via '--subject'")
  CALL checkNULL(from,"From must be given via '--from'")
  CALL checkNULL(to,"To must be given via '--to'")
  IF proto<>"smtp" AND proto<>"smpts" THEN
    CALL myerr(sfmt("wrong '--protocol %1' option,must be either 'smtp' or 'smpts'",proto))
  END IF
  IF port<>25 AND port<>465 AND port<>587 THEN
    CALL myerr(sfmt("wrong '--port %1' option,must be 25,465 or 587",port))
  END IF
  IF bodyfile IS NOT NULL THEN
    LET body=readFile(bodyfile)
  END IF

  LET props=System.getProperties()
  LET sarr[1]=proto
  CALL props.put(String.format("mail.%s.port",sarr),port) --String.format needs an object array in 4GL which has one string
  IF tls THEN
    CALL props.put(String.format("mail.%s.starttls.enable",sarr),"true")
  END IF
  IF user IS NOT NULL AND pass IS NOT NULL THEN
    CALL props.put(String.format("mail.%s.auth",sarr),"true")
  END IF
  --CALL props.put(String.format("mail.%s.ssl.enable",sarr),"true")
  { switch off identity trust
  IF host="smptp.yourdomain.com" THEN
    CALL props.put(String.format("mail.%s.ssl.checkserveridentity",sarr),"false")
    CALL props.put(String.format("mail.%s.ssl.trust",sarr),"*")
  END IF
  }
  LET sess=Session.getInstance(props,CAST(mynull as Authenticator)) --leo:there should be a more convenient way to pass a null pointer
  CALL sess.setDebug(TRUE)
  LET msg=MimeMessage.create(sess)
  CALL msg.setFrom(InternetAddress.create(from))
  CALL msg.setRecipients(Message.RecipientType.TO,InternetAddress.parse(to, FALSE));
  CALL msg.setSubject(subject)
  CALL msg.setText(body)
  LET trans =CAST(sess.getTransport(proto) AS SMTPTransport)
  CALL trans.connect(host, user, pass);
  CALL trans.sendMessage(msg,msg.getAllRecipients())
END MAIN

FUNCTION help()
  DEFINE i INT
  DISPLAY sfmt("usage: fglrun %1 ?option value?",arg_val(0))
  DISPLAY "Possible options:"
  DISPLAY   "  short   long\t\t value"
  FOR i=1 TO optarr.getLength()
    DISPLAY "  ",optarr[i]
  END FOR
  EXIT PROGRAM 1
END FUNCTION
  
FUNCTION checkNULL(s,txt)
  DEFINE s,txt STRING
  IF s IS NULL THEN
    CALL myerr(txt)
  END IF
END FUNCTION

FUNCTION myerr(err)
  DEFINE err STRING
  DISPLAY "ERROR:",err
  EXIT PROGRAM 1
END FUNCTION

FUNCTION readFile(f)
  DEFINE f STRING
  DEFINE t TEXT
  IF NOT os.Path.exists(f) THEN
    CALL myerr(sfmt("bodyfile '%1' does not exist",f))
  END IF
  LOCATE t in FILE f
  LET f=t
  RETURN f
END FUNCTION
