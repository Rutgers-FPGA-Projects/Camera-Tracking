import smtplib

def sendemail(from_addr, to_addr_list, cc_addr_list,
              subject, message,
              login, password,
              smtpserver='smtp.gmail.com:587'):
    header  = 'From: %s\n' % from_addr
    header += 'To: %s\n' % ','.join(to_addr_list)
    header += 'Cc: %s\n' % ','.join(cc_addr_list)
    header += 'Subject: %s\n\n' % subject
    message = header + message
    
    server = smtplib.SMTP(smtpserver)
    server.starttls()
    server.login(login,password)
    problems = server.sendmail(from_addr, to_addr_list, message)
    server.quit()
    return problems

sendemail(from_addr    = 'haoyang.yu@rutgers.edu',
          to_addr_list = ['yhyyhyyyl@gmail.com'],
          cc_addr_list = ['yhy.haoyang.yu@gmail.com'],
          subject      = 'Caution',
          message      = 'Dear Camera Tracking Group, I have detected the objected object at the moment, please pay attention to this email and take specific action',
          login        = 'hy214@scarletmail.rutgers.edu',
          password     = 'XXX')