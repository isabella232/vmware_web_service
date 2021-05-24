require 'VMwareWebService/logging'

class MiqVimFolder
  include VMwareWebService::Logging

  attr_reader :name, :invObj

  def initialize(invObj, fh)
    @invObj   = invObj
    @sic    = invObj.sic

    @fh     = fh
    @name   = @fh["name"]
    @fMor   = @fh["MOR"]
  end

  #
  # Called when client is finished using this MiqVimVm object.
  # The server will delete its reference to the object, so the
  # server-side object csn be GC'd
  #
  def release
    # @invObj.releaseObj(self)
  end

  def reload
    @fh = @invObj.getMoProp(@fMor)
  end

  def fMor
    (@fMor)
  end

  def fh
    (@fh)
  end

  def registerVM(path, name, pool = nil, host = nil, asTemplate = false)
    hmor = pmor = nil
    hmor = (host.kind_of?(Hash) ? host['MOR'] : host) if host
    pmor = (pool.kind_of?(Hash) ? pool['MOR'] : pool) if pool

    logger.info "MiqVimFolder(#{@invObj.server}, #{@invObj.username}).registerVM: calling registerVM_Task"
    taskMor = @invObj.registerVM_Task(@fMor, path, name, asTemplate.to_s, pmor, hmor)
    logger.info "MiqVimFolder(#{@invObj.server}, #{@invObj.username}).registerVM: returned from registerVM_Task"
    logger.debug "MiqVimFolder::registerVM: taskMor = #{taskMor}"
    waitForTask(taskMor)
  end

  def addStandaloneHost(hostName, userName, password, *args)
    ah = {:force => false, :wait => true, :asConnected => true}

    if args.length == 1 && args.first.kind_of?(Hash)
      ah.merge!(args.first)
    elsif args.length > 1
      ah.merge!(Hash[*args])
    end

    cspec = VimHash.new('HostConnectSpec') do |cs|
      cs.force        = ah[:force].to_s
      cs.hostName       = hostName
      cs.userName       = userName
      cs.password       = password
      cs.managementIp     = ah[:managementIp]     unless ah[:managementIp].nil?
      cs.port         = ah[:port]         unless ah[:port].nil?
      cs.sslThumbprint    = ah[:sslThumbprint]    unless ah[:sslThumbprint].nil?
      cs.vimAccountName   = ah[:vimAccountName]   unless ah[:vimAccountName].nil?
      cs.vimAccountPassword = ah[:vimAccountPassword] unless ah[:vimAccountPassword].nil?
      cs.vmFolder       = ah[:vmFolder]       unless ah[:vmFolder].nil?
    end

    logger.info "MiqVimCluster(#{@invObj.server}, #{@invObj.username}).addStandaloneHost: calling addStandaloneHost_Task"
    taskMor = @invObj.addStandaloneHost_Task(@fMor, cspec, ah[:asConnected].to_s, ah[:license])
    logger.info "MiqVimCluster(#{@invObj.server}, #{@invObj.username}).addStandaloneHost: returned from addStandaloneHost_Task"
    return taskMor unless ah[:wait]
    waitForTask(taskMor)
  end # def addStandaloneHost

  # Places vCenterObject into current folder, removing it from other folders
  def moveIntoFolder(vCenterObject)
    oMor = nil
    oMor = (vCenterObject.kind_of?(Hash) ? vCenterObject['MOR'] : vCenterObject) if vCenterObject

    logger.info "MiqVimFolder(#{@invObj.server}, #{@invObj.username}).moveIntoFolder: calling moveIntoFolder_Task"
    taskMor = @invObj.moveIntoFolder_Task(@fMor, oMor)
    logger.info "MiqVimFolder(#{@invObj.server}, #{@invObj.username}).moveIntoFolder: returned from moveIntoFolder_Task"
    logger.debug "MiqVimFolder::moveIntoFolder: taskMor = #{taskMor}"
    waitForTask(taskMor)
  end

  # Creates empty VM, that can be installed later from ISO or whatever
  #
  # configSpec   - describes VM details, it should be filled in calling code since there are too many possible options
  # pool         - VMware resource pool new VM will belong to
  # host         - VMware host this VM should start on, it can be nil if pool is on DRS cluster or single-host cluster
  #
  # Returns MOR of new VM
  def createVM(configSpec, pool, host = nil)
    hMor = pMor = nil
    hMor = (host.kind_of?(Hash) ? host['MOR'] : host) if host
    pMor = (pool.kind_of?(Hash) ? pool['MOR'] : pool) if pool

    logger.info "MiqVimFolder(#{@invObj.server}, #{@invObj.username}).createVM calling createVM_Task"
    taskMor = @invObj.createVM_Task(@fMor, configSpec, pMor, hMor)
    logger.info "MiqVimFolder(#{@invObj.server}, #{@invObj.username}).createVM returned from createVM_Task"
    logger.debug "MiqVimFolder::createVM: taskMor = #{taskMor}"
    waitForTask(taskMor)
  end

  def createFolder(fname)
    @invObj.createFolder(@fMor, fname)
  end

  def subFolderMors
    fh['childEntity'].each_with_object([]) do |ce, ra|
      ra << ce if ce.vimType == 'Folder'
    end
  end

  def waitForTask(tmor)
    @invObj.waitForTask(tmor, self.class.to_s)
  end
end
