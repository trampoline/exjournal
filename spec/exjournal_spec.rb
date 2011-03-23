require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Exjournal" do
  describe "extract_journalled_mail" do
    it "should extract the first message/rfc822 attachment without content" do
      s=File.read(File.expand_path("../fixtures/email_with_email_attachment.eml", __FILE__))
      jm = Exjournal.extract_journalled_mail(s)
      jm.message_id.should == "<0FDFBAF6-0960-40FB-B730-B0C7C3299948@empire42.com>"
      jm.body.should =~ /\s*/
    end

    it "should extract the first message/rfc822 attachment with content" do
      s=File.read(File.expand_path("../fixtures/email_with_email_attachment.eml", __FILE__))
      jm = Exjournal.extract_journalled_mail(s, false)
      jm.message_id.should == "<0FDFBAF6-0960-40FB-B730-B0C7C3299948@empire42.com>"
      jm.body.should !~ /\s*/
    end

    it "should raise if there is no message/rfc822 attachment" do
      s=File.read(File.expand_path("../fixtures/email_without_attachment.eml", __FILE__))
      lambda{
        Exjournal.extract_journalled_mail(s)
      }.should raise_error(/has no attachments/)
    end
  end

  describe "discard_mail_body" do
    it "should discard everything after \r\n\r\n" do
      s=<<-EOF
From: foo@bar.com\r
To: baz@boo.com\r
Subject: i can't tell you\r
\r
because it's a secret\r
      EOF
      Exjournal.discard_mail_body(s).should =~ /^From: foo@bar.com.*tell you$/m
    end

    it "should do nothing if no \r\n\r\n" do
      s=<<-EOF
From: foo@bar.com\r
To: baz@boo.com\r
Subject: i can't tell you
      EOF
      Exjournal.discard_mail_body(s).should == s
    end
  end

  describe "strip_header" do
    it "should strip angle brackets if present" do
      Exjournal.strip_header("<foo>").should == "foo"
    end

    it "should do nothing if no angle brackets" do
      Exjournal.strip_header("foo").should == "foo"
    end
  end

  describe "strip_headers" do
    it "should strip_header from a single header" do
      Exjournal.strip_headers("<foo>").should == ["foo"]
    end

    it "should strip_header from more than one header" do
      Exjournal.strip_headers(["<foo>", "<bar>"]).should == ["foo", "bar"]
    end
  end

  describe "parse_address" do
    it "should extract a hash from an address" do
      h = Exjournal.parse_address(TMail::Address.parse('"foo mcfoo" <foo@bar.com>'))
      h.should == {:name=>"foo mcfoo", :address=>"foo@bar.com"}
    end
  end

  describe "parse_addresses" do
    it "should extract a hash from a single address" do
      h = Exjournal.parse_addresses(TMail::Address.parse('"foo mcfoo" <foo@bar.com>'))
      h.should == [{:name=>"foo mcfoo", :address=>"foo@bar.com"}]
    end

    it "should extract hashes from more than one address" do
      h = Exjournal.parse_addresses([TMail::Address.parse('"foo mcfoo" <foo@bar.com>'),
                                     TMail::Address.parse('"baz mcbaz" <baz@boo.com>')])
      h.should == [{:name=>"foo mcfoo", :address=>"foo@bar.com"},
                   {:name=>"baz mcbaz", :address=>"baz@boo.com"}]
    end
  end

  describe "mail_to_hash" do
    it "should turn a mail to json excluding subject" do
      s=File.read(File.expand_path("../fixtures/email_with_references.eml", __FILE__))    
      h = Exjournal.mail_to_hash(s)

      h[:message_id].should == "B63CAA43-F378-4033-BA8B-ED408805B5B5@empire42.com"
      h[:sent_at].should == DateTime.parse('Wed, 21 Apr 2010 14:43:24 +0100').xmlschema
      h[:in_reply_to].should == ["B63CAA43-F378-4033-BA8B-foo@empire42.com"]
      h[:references].should == ["B63CAA43-F378-4033-BA8B-foo@empire42.com", 
                                "B63CAA43-F378-4033-BA8B-bar@empire42.com", 
                                "B63CAA43-F378-4033-BA8B-baz@empire42.com"]
      h[:from].should == {:name=>"Peter MacRobert", :address=>"peter.macrobert@empire42.com"}
      h[:to].should == [{:name=>nil, :address=>"foo@bar.com"},
                        {:name=>"bar mcbar", :address=>"bar.mcbar@bar.com"}]
      h[:cc].should == []
      h[:bcc].should == []
      h[:subject].should == nil
    end

    it "should turn a mail to json including subject" do
      s=File.read(File.expand_path("../fixtures/email_with_references.eml", __FILE__))    
      h = Exjournal.mail_to_hash(s, false)

      h[:message_id].should == "B63CAA43-F378-4033-BA8B-ED408805B5B5@empire42.com"
      h[:sent_at].should == DateTime.parse('Wed, 21 Apr 2010 14:43:24 +0100').xmlschema
      h[:in_reply_to].should == ["B63CAA43-F378-4033-BA8B-foo@empire42.com"]
      h[:references].should == ["B63CAA43-F378-4033-BA8B-foo@empire42.com", 
                                "B63CAA43-F378-4033-BA8B-bar@empire42.com", 
                                "B63CAA43-F378-4033-BA8B-baz@empire42.com"]
      h[:from].should == {:name=>"Peter MacRobert", :address=>"peter.macrobert@empire42.com"}
      h[:to].should == [{:name=>nil, :address=>"foo@bar.com"},
                        {:name=>"bar mcbar", :address=>"bar.mcbar@bar.com"}]
      h[:cc].should == []
      h[:bcc].should == []
      h[:subject].should == "Test email"
    end
  end
end
