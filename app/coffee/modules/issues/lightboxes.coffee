###
# Copyright (C) 2014 Andrey Antukh <niwi@niwi.be>
# Copyright (C) 2014 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014 David Barragán Merino <bameda@dbarragan.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: modules/issues/lightboxes.coffee
###

taiga = @.taiga
bindOnce = @.taiga.bindOnce
debounce = @.taiga.debounce

module = angular.module("taigaIssues")

#############################################################################
## Issue Create Lightbox Directive
#############################################################################

CreateIssueDirective = ($repo, $confirm, $rootscope, lightboxService) ->
    link = ($scope, $el, $attrs) ->
        form = $el.find("form").checksley()
        $scope.issue = {}

        $scope.$on "issueform:new", (ctx, project)->
            lightboxService.open($el)

            $scope.issue = {
                project: project.id
                subject: ""
                status: project.default_issue_status
                type: project.default_issue_type
                priority: project.default_priority
                severity: project.default_severity
                tags: []
            }

        $scope.$on "$destroy", ->
            $el.off()

        submit = debounce 2000, ->
            if not form.validate()
                return

            promise = $repo.create("issues", $scope.issue)

            promise.then (data) ->
                $rootscope.$broadcast("issueform:new:success", data)
                lightboxService.close($el)
                $confirm.notify("success")

            promise.then null, ->
                $confirm.notify("error")

        $el.on "click", ".button-green", (event) ->
            event.preventDefault()
            submit()

        $el.on "submit", "form", (event) ->
            event.preventDefault()
            submit()

    return {link:link}

module.directive("tgLbCreateIssue", ["$tgRepo", "$tgConfirm", "$rootScope", "lightboxService",
                                     CreateIssueDirective])


#############################################################################
## Issue Bulk Create Lightbox Directive
#############################################################################

CreateBulkIssuesDirective = ($repo, $rs, $confirm, $rootscope, lightboxService) ->
    link = ($scope, $el, attrs) ->
        $scope.$on "issueform:bulk", (ctx, projectId, status)->
            lightboxService.open($el)
            $scope.new = {
                projectId: projectId
                bulk: ""
            }

        $el.on "click", ".button-green", debounce 2000, (event) ->
            event.preventDefault()

            form = $el.find("form").checksley()
            if not form.validate()
                return

            data = $scope.new.bulk
            projectId = $scope.new.projectId

            promise = $rs.issues.bulkCreate(projectId, data)
            promise.then (result) ->
                $rootscope.$broadcast("issueform:new:success", result)
                lightboxService.close($el)
                $confirm.notify("success")

            promise.then null, ->
                $confirm.notify("error")

        $scope.$on "$destroy", ->
            $el.off()

    return {link: link}

module.directive("tgLbCreateBulkIssues", ["$tgRepo", "$tgResources", "$tgConfirm", "$rootScope",
                                          "lightboxService", CreateBulkIssuesDirective])
